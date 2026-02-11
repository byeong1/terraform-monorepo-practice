<template>
  <div class="container">
    <nav class="tabs">
      <button :class="{ active: tab === 'items' }" @click="tab = 'items'">Items</button>
      <button :class="{ active: tab === 'videos' }" @click="tab = 'videos'">Videos</button>
    </nav>

    <!-- Items Tab -->
    <div v-if="tab === 'items'">
      <form class="form" @submit.prevent="addItem">
        <input v-model="newItem.name" placeholder="Name" required />
        <input v-model="newItem.description" placeholder="Description" />
        <button type="submit">Add</button>
      </form>

      <ul class="list">
        <li v-for="item in items" :key="item.id">
          <div>
            <strong>{{ item.name }}</strong>
            <span v-if="item.description"> - {{ item.description }}</span>
          </div>
          <button @click="deleteItem(item.id)">Delete</button>
        </li>
      </ul>
    </div>

    <!-- Videos Tab -->
    <VideoList v-if="tab === 'videos'" />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from "vue";
import VideoList from "./components/VideoList.vue";

const tab = ref("items");
const items = ref([]);
const newItem = reactive({ name: "", description: "" });

const fetchItems = async () => {
  const res = await fetch("/api/items");
  items.value = await res.json();
};

const addItem = async () => {
  await fetch("/api/items", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(newItem),
  });
  newItem.name = "";
  newItem.description = "";
  await fetchItems();
};

const deleteItem = async (id) => {
  await fetch(`/api/items/${id}`, { method: "DELETE" });
  await fetchItems();
};

onMounted(fetchItems);
</script>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}
body {
  font-family: sans-serif;
  background: #f5f5f5;
  padding: 2rem;
}
.container {
  max-width: 800px;
  margin: 0 auto;
}
.tabs {
  display: flex;
  gap: 0;
  margin-bottom: 1.5rem;
  border-bottom: 2px solid #ddd;
}
.tabs button {
  padding: 0.5rem 1.5rem;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 1rem;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  color: #666;
}
.tabs button.active {
  border-bottom-color: #1976d2;
  color: #1976d2;
  font-weight: bold;
}
.form {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}
.form input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.form button {
  padding: 0.5rem 1rem;
  background: #4caf50;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.list {
  list-style: none;
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
.list li button {
  background: #e53935;
  color: #fff;
  border: none;
  padding: 0.3rem 0.75rem;
  border-radius: 4px;
  cursor: pointer;
}
</style>
