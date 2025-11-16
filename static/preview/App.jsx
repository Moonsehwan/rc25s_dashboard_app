```jsx
import React, { useState, useEffect } from 'react';
import './App.css';

const App = () => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('https://api.example.com/data');
        if (!response.ok) throw new Error('Network response was not ok');
        const result = await response.json();
        setData(result);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const renderContent = () => {
    if (loading) {
      return <div className="loader">Loading...</div>;
    }

    if (error) {
      return <div className="error">Error: {error}</div>;
    }

    if (!data.length) {
      return <div className="no-data">No data available</div>;
    }

    return (
      <ul className="data-list">
        {data.map(({ id, title, description }) => (
          <li key={id} className="data-item">
            <h2 className="item-title">{title}</h2>
            <p className="item-description">{description}</p>
          </li>
        ))}
      </ul>
    );
  };

  return (
    <div className="app-container">
      <header className="app-header">
        <h1 className="app-title">Dynamic Data Display</h1>
      </header>
      <main className="app-content">
        {renderContent()}
      </main>
      <footer className="app-footer">
        <p className="footer-text">© {new Date().getFullYear()} Your Company. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default App;
```