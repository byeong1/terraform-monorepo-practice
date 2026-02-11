<template>
  <div class="upload-section">
    <h3>Upload Video</h3>
    <form @submit.prevent="startUpload">
      <input v-model="title" placeholder="Video title" required />
      <input type="file" ref="fileInput" accept="video/mp4" required @change="onFileSelect" />
      <button type="submit" :disabled="uploading">
        {{ uploading ? 'Uploading...' : 'Upload' }}
      </button>
    </form>
    <div v-if="uploading" class="progress-bar">
      <div class="progress-fill" :style="{ width: progress + '%' }"></div>
      <span class="progress-text">{{ progress }}%</span>
    </div>
    <p v-if="error" class="error">{{ error }}</p>
  </div>
</template>

<script setup>
import { ref, useTemplateRef } from 'vue';

const PART_SIZE = 10 * 1024 * 1024; // 10MB

const emit = defineEmits(['uploaded']);

const title = ref('');
const file = ref(null);
const uploading = ref(false);
const progress = ref(0);
const error = ref('');
const fileInput = useTemplateRef('fileInput');

const onFileSelect = (e) => {
  file.value = e.target.files[0] || null;
};

const startUpload = async () => {
  if (!file.value || !title.value) return;
  uploading.value = true;
  progress.value = 0;
  error.value = '';

  try {
    const createRes = await fetch('/api/videos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: title.value,
        mimeType: file.value.type,
        fileSize: file.value.size,
      }),
    });
    const { video } = await createRes.json();
    const videoId = video.id;

    const initRes = await fetch(`/api/videos/${videoId}/multipart/init`, {
      method: 'POST',
    });
    const { uploadId } = await initRes.json();

    const totalParts = Math.ceil(file.value.size / PART_SIZE);
    const parts = [];

    for (let i = 0; i < totalParts; i++) {
      const start = i * PART_SIZE;
      const end = Math.min(start + PART_SIZE, file.value.size);
      const blob = file.value.slice(start, end);
      const partNumber = i + 1;

      const urlRes = await fetch(`/api/videos/${videoId}/multipart/url`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ uploadId, partNumber }),
      });
      const { url } = await urlRes.json();

      const uploadRes = await fetch(url, {
        method: 'PUT',
        body: blob,
      });

      parts.push({
        ETag: uploadRes.headers.get('ETag'),
        PartNumber: partNumber,
      });

      progress.value = Math.round(((i + 1) / totalParts) * 100);
    }

    await fetch(`/api/videos/${videoId}/multipart/complete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ uploadId, parts }),
    });

    title.value = '';
    file.value = null;
    if (fileInput.value) fileInput.value.value = '';
    emit('uploaded');
  } catch (e) {
    error.value = 'Upload failed: ' + e.message;
    console.error(e);
  } finally {
    uploading.value = false;
  }
};
</script>

<style scoped>
.upload-section {
  margin-bottom: 2rem;
  padding: 1rem;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
.upload-section h3 {
  margin-bottom: 0.75rem;
}
.upload-section form {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  flex-wrap: wrap;
}
.upload-section input[type="text"],
.upload-section input:not([type]) {
  flex: 1;
  min-width: 150px;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.upload-section button {
  padding: 0.5rem 1rem;
  background: #1976d2;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.upload-section button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.progress-bar {
  margin-top: 0.75rem;
  background: #e0e0e0;
  border-radius: 4px;
  height: 24px;
  position: relative;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: #1976d2;
  transition: width 0.3s;
}
.progress-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 0.75rem;
  font-weight: bold;
  color: #333;
}
.error {
  color: #e53935;
  margin-top: 0.5rem;
}
</style>
