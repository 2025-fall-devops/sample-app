const http = require(
    'http'
);

const server = http.createServer(
    (req, res) => {
        res.writeHead(
            200
            , { 
                'Content-Type': 'text/plain' 
            }
        );
        res.end(
`Hello, World ! ! !

The time on the server is ${new Date().toLocaleString()}`
        );
    }
);

// Get port from .env file, or uses port 8080 in not in .env file...
const port = process.env.PORT || 8080;

server.listen(
    port
    , () => {
        console.log(
            `Listening on port ${port}`
        );
    }
);