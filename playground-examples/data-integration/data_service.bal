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
        methods:["POST"],
        path:"/customer"
    }
    customers (endpoint client, http:Request req) {

        // Retrieve customer data from request.
        json customerReq =? req.getJsonPayload();
        string name = customerReq.name.toString();
        int age =? <int> customerReq.age.toString();

        sql:Parameter[] params = [];
        sql:Parameter para1 = {sqlType:sql:Type.VARCHAR, value:name};
        sql:Parameter para2 = {sqlType:sql:Type.INTEGER, value:age};
        params = [para1, para2];

        int update_row_cnt =? customers_db -> update("INSERT INTO CUSTOMER (NAME, AGE) VALUES (?,?)", params);
        log:printInfo("Inserted row count:" + update_row_cnt);

        table dt =? customers_db -> select("SELECT * FROM CUSTOMER", null, null);

        // Transform data table into JSON
        var response =? <json>dt;
        http:Response res = {};
        res.setJsonPayload(response);
        // Respond back to the client.
        _ = client -> respond(res);

        //ToDO: Handle errors and customers_db.close();
    }
}
