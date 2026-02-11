<template>
  <div class="video-player">
    <video ref="videoEl" class="video-js vjs-default-skin vjs-big-play-centered"></video>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import videojs from 'video.js';
import 'video.js/dist/video-js.css';
import 'jb-videojs-hls-quality-selector';

const props = defineProps({
  src: { type: String, required: true },
});

const videoEl = ref(null);
let player = null;

onMounted(() => {
  player = videojs(videoEl.value, {
    controls: true,
    autoplay: false,
    preload: 'auto',
    fluid: true,
    sources: [{ src: props.src, type: 'application/x-mpegURL' }],
  });
  player.hlsQualitySelector({ displayCurrentQuality: true });
});

onBeforeUnmount(() => {
  if (player) player.dispose();
});

watch(() => props.src, (newSrc) => {
  if (player) player.src({ src: newSrc, type: 'application/x-mpegURL' });
});
</script>

<style scoped>
.video-player {
  max-width: 800px;
  margin: 0 auto;
}
</style>
