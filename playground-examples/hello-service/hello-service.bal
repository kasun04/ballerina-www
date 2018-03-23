import ballerina/net.http;
import ballerina/io;

endpoint http:ServiceEndpoint helloWorldEP {
    port:9090
};

@http:ServiceConfig { basePath:"/hello" }
service<http:Service> helloWorld bind helloWorldEP {

    @http:ResourceConfig {
        path:"/", 
        methods:["POST"]
    }
    sayHello (endpoint conn, http:Request req) {
        http:Response res = {};    
        var req_payload = req.getStringPayload();
        match req_payload {
            string req_str => {
                res.setStringPayload("Hello, World!, " + req_str + "\n");
            } 
            any | null => {
        		io:println("No payload found!");
            }
        }
        _ = conn -> respond(res);
    }
}