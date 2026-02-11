<template>
  <div class="video-list">
    <VideoUpload @uploaded="fetchVideos" />

    <h3>Videos</h3>
    <div v-if="loading">Loading...</div>

    <ul class="list">
      <li v-for="video in videos" :key="video.id">
        <div class="video-info">
          <strong>{{ video.title }}</strong>
          <span :class="'badge badge-' + video.status">{{ video.status }}</span>
        </div>
        <div class="video-actions">
          <button class="play-btn" :disabled="video.status !== 'ready'" @click="playVideo(video)">
            Play
          </button>
          <button class="delete-btn" @click="deleteVideo(video.id)">Delete</button>
        </div>
      </li>
    </ul>

    <p v-if="!loading && videos.length === 0" class="empty">No videos yet.</p>

    <div v-if="currentVideo" class="player-overlay" @click.self="currentVideo = null">
      <div class="player-modal">
        <div class="player-header">
          <h3>{{ currentVideo.title }}</h3>
          <button @click="currentVideo = null">Close</button>
        </div>
        <VideoPlayer :src="currentVideo.hlsUrl" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import VideoPlayer from './VideoPlayer.vue';
import VideoUpload from './VideoUpload.vue';

const videos = ref([]);
const loading = ref(false);
const currentVideo = ref(null);
let pollTimer = null;

const needsPolling = () => {
  return videos.value.some(v => v.status === 'pending' || v.status === 'uploading' || v.status === 'encoding');
};

const startPolling = () => {
  if (pollTimer) return;
  pollTimer = setInterval(fetchVideos, 10000);
};

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const fetchVideos = async () => {
  loading.value = videos.value.length === 0;
  try {
    const res = await fetch('/api/videos');
    videos.value = await res.json();
  } catch (e) {
    console.error(e);
  } finally {
    loading.value = false;
  }

  if (needsPolling()) {
    startPolling();
  } else {
    stopPolling();
  }
};

const playVideo = async (video) => {
  const res = await fetch(`/api/videos/${video.id}`);
  const data = await res.json();
  if (data.hlsUrl) currentVideo.value = data;
};

const deleteVideo = async (id) => {
  if (!confirm('Delete this video?')) return;
  await fetch(`/api/videos/${id}`, { method: 'DELETE' });
  currentVideo.value = null;
  await fetchVideos();
};

onMounted(() => {
  fetchVideos();
});

onBeforeUnmount(() => {
  stopPolling();
});
</script>

<style scoped>
.video-list h3 {
  margin-bottom: 0.75rem;
}
.list {
  list-style: none;
  padding: 0;
}
.list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fff;
  padding: 0.75rem 1rem;
  margin-bottom: 0.5rem;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
.video-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.badge {
  font-size: 0.7rem;
  padding: 2px 8px;
  border-radius: 10px;
  font-weight: bold;
  text-transform: uppercase;
}
.badge-pending { background: #fff3e0; color: #e65100; }
.badge-uploading { background: #e3f2fd; color: #1565c0; }
.badge-encoding { background: #f3e5f5; color: #6a1b9a; }
.badge-ready { background: #e8f5e9; color: #2e7d32; }
.badge-error { background: #ffebee; color: #c62828; }
.video-actions {
  display: flex;
  gap: 0.5rem;
}
.play-btn {
  background: #1976d2;
  color: #fff;
  border: none;
  padding: 0.3rem 0.75rem;
  border-radius: 4px;
  cursor: pointer;
}
.play-btn:disabled {
  background: #b0bec5;
  cursor: not-allowed;
}
.delete-btn {
  background: #e53935;
  color: #fff;
  border: none;
  padding: 0.3rem 0.75rem;
  border-radius: 4px;
  cursor: pointer;
}
.empty {
  color: #888;
}
.player-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.player-modal {
  background: #fff;
  border-radius: 8px;
  padding: 1rem;
  width: 90%;
  max-width: 900px;
}
.player-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}
.player-header button {
  background: none;
  border: 1px solid #ccc;
  padding: 0.3rem 0.75rem;
  border-radius: 4px;
  cursor: pointer;
}
</style>
