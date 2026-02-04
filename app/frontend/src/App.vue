<template>
  <div class="container">
    <h1>Items</h1>

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
</template>

<script>
export default {
  data() {
    return {
      items: [],
      newItem: { name: "", description: "" },
    };
  },
  mounted() {
    this.fetchItems();
  },
  methods: {
    async fetchItems() {
      const res = await fetch("/api/items");
      this.items = await res.json();
    },
    async addItem() {
      await fetch("/api/items", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(this.newItem),
      });
      this.newItem = { name: "", description: "" };
      await this.fetchItems();
    },
    async deleteItem(id) {
      await fetch(`/api/items/${id}`, { method: "DELETE" });
      await this.fetchItems();
    },
  },
};
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
  max-width: 600px;
  margin: 0 auto;
}
h1 {
  margin-bottom: 1rem;
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
