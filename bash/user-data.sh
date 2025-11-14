#!/usr/bin/env bash

set -e

tee /etc/yum.repos.d/nodesource-nodejs.repo > /dev/null <<EOF
[nodesource-nodejs]
baseurl=https://rpm.nodesource.com/pub_23.x/nodistro/nodejs/x86_64
gpgkey=https://rpm.nodesource.com/gpgkey/ns-operations-public.key
EOF
yum install -y nodejs

tee app.js > /dev/null << "EOF"
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
`Hello, World! ! !

The time on the server is ${new Date().toLocaleString()}

The D6 Rolled a ${Math.floor(Math.random() * 6) + 1}`
        );          
    }
);

// Get port from .env file, or uses port 80 in in .env file....
const port = process.env.PORT || 80; 

server.listen(
    port
    ,() => {
        console.log(
            `Listening on port ${port}`
        );
    }
);
EOF

nohup node app.js &