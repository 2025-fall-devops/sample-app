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
`Hello, World of DevOps!

The server time is ${new Date().toLocaleString()}`
        );
    }
);

const port = process.env.PORT || 8080;
server.listen(
    port
    ,() => {
        console.log(`Listening on port ${port}`
        );
    }
);