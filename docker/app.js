const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(`FUNdamentals of DevOps ! ! !

    The time on the server is ${new Date().toLocaleString()}
    
    The D12 rolled a ${Math.floor(Math.random()*12)+1}`);
});

const port = process.env.PORT || 8080;
server.listen(port,() => {
  console.log(`Listening on port ${port}`);
});
