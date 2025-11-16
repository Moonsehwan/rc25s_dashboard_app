import React, { useState, useEffect } from 'react';
import axios from 'axios';

const App = () => {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState(1);

  const fetchTasks = async () => {
    const response = await axios.get('http://localhost:8000/tasks/');
    setTasks(response.data);
  };

  const addTask = async () => {
    const newTask = { id: tasks.length + 1, title, description, priority, context: 'general' };
    await axios.post('http://localhost:8000/tasks/', newTask);
    fetchTasks();
  };

  const deleteTask = async (id) => {
    await axios.delete(`http://localhost:8000/tasks/${id}`);
    fetchTasks();
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  return (
    <div>
      <h1>AI Todo Dashboard</h1>
      <input placeholder='Task Title' value={title} onChange={(e) => setTitle(e.target.value)} />
      <textarea placeholder='Task Description' value={description} onChange={(e) => setDescription(e.target.value)}></textarea>
      <select value={priority} onChange={(e) => setPriority(parseInt(e.target.value))}>
        <option value={1}>High</option>
        <option value={2}>Medium</option>
        <option value={3}>Low</option>
      </select>
      <button onClick={addTask}>Add Task</button>
      <ul>
        {tasks.map((task) => (
          <li key={task.id}>\n            {task.title} - {task.description} - Priority: {task.priority} <button onClick={() => deleteTask(task.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default App;