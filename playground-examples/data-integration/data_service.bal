import ballerina/net.http;
import ballerina/data.sql;
import ballerina/io;
import ballerina/log;

// Service endpoint for 'hello' backend service
endpoint http:ServiceEndpoint dataServiceEP {
    port:9090
};

// SQL endpoint
endpoint sql:Client customers_db {
    database:sql:DB.H2_FILE,
    host:"./",
    port:10,
    name:"CUSTOMER_DB",
    username:"root",
    password:"root",
    options:{maximumPoolSize:5}
};

const string  CUSTOMER_DB = "customer_db";

@Description {value:"Service backed by a H2 database."}
@http:ServiceConfig {
    basePath:"/"
}
service<http:Service> data_service bind dataServiceEP {

    @Description {value:"Resource that retrieves customer creation requts and insert the customers into the database."}
    @http:ResourceConfig {
        methods:["POST"], path:"/customer", consumes:["application/json"], produces:["application/json"]
    }
    customers (endpoint client, http:Request req) {
        http:Response res = {};
        json customer;
        json responsePayload;
        string name = "";
        int age;
        // Retrieve customer data from request.
        var customerReqVar = req.getJsonPayload();
        match customerReqVar {
            // Valid JSON payload
            json customerReq => {
                customer = customerReq;
            }
            // NOT a valid JSON payload
            any | null => {
                responsePayload = {"Message":"Invalid payload - Not a valid JSON payload"};
                res.setJsonPayload(responsePayload);
                _ = client -> respond(res);
                return;
            }
        }

        match customer.name {
            string nameVal => {
                name = nameVal;
            }
            // Error accessing field 'name'
            any | null => {
                responsePayload = {"Message":"Invalid payload - Error in field 'name'"};
                res.setJsonPayload(responsePayload);
                _ = client -> respond(res);
                return;
            }
        }

        match customer.age {
            int ageVal => {
                age = ageVal;
            }
            // Error accessing field 'age' or invalid value
            any | null => {
                responsePayload = {"Message":"Invalid payload - Error in field 'age' or invalid value specified"};
                res.setJsonPayload(responsePayload);
                _ = client -> respond(res);
                return;
            }
        }

        //string name = customerReq.name.toString();
        //int age =? <int> customerReq.age.toString();

        sql:Parameter[] params = [];
        sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
        sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
        params = [para1, para2];

        int update_row_cnt =? customers_db -> update("INSERT INTO CUSTOMER (NAME, AGE) VALUES (?,?)", params);
        log:printInfo("Inserted row count:" + update_row_cnt);

        table dt =? customers_db -> select("SELECT * FROM CUSTOMER", null, null);

        // Transform data table into JSON
        responsePayload =? <json>dt;
        res.setJsonPayload(responsePayload);
        // Respond back to the client.
        _ = client -> respond(res);

        //ToDO: Handle errors and customers_db.close();
    }
}
