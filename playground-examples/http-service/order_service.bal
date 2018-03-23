import ballerina/net.http;
import ballerina/log;


endpoint http:ServiceEndpoint orderServiceEP {
    port:9090
};


@Description {value:"Simple order retrieval service."}
@http:ServiceConfig {basePath:"/"}
service<http:Service> OrderService bind orderServiceEP {

    map orders_map = {"1":"sample order : 1\n", "2":"sample order :2\n"};

    @Description {value:"Resource that retrieves order based on the order id path parameter."}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    findOrder (endpoint client, http:Request req, string orderId) {
        http:Response res = {};    
        var order_content = orders_map[orderId];
        
        match order_content {
            string s => res.setStringPayload(s);
            any => { 
                log:printError("Invalid Order"); 
                // Set 500 status code for invalid orders.
                res.statusCode = 500;
                string error_message = "Invalid order : Order ID - " + orderId;
                res.setStringPayload(error_message);
                log:printInfo(error_message);
            }
        }

        // Respond back to the client.
        _ = client->respond(res);
    }
}
