@isTest
global class SmartCarCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        String endpoint = req.getEndpoint();

        if (endpoint.endsWith('/vehicles')) {
            res.setBody('{"v1": {"VIN123": {"id": "car-123", "make": "Tesla", "model": "Model 3", "year": 2022}}}');
        } 
        else if (endpoint.contains('/odometer')) {
            res.setBody('{"distance": 55043.0}');
        } 
        else if (endpoint.contains('/location')) {
            res.setBody('{"latitude": 37.41, "longitude": -122.09}');
        }

        return res;
    }
}