const path = require('path');
const express = require('express');
const app = express();

app.use(express.static('public'));

app.get('/chunks.js', (req, res) => {
  res.sendFile(path.join(__dirname,'chunks.js'));
});

app.listen(3000, () => {
  console.log('listening on port 3000');
});