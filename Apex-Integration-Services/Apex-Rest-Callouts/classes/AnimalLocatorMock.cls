public class AnimalLocatorMock implements HttpCalloutMock {

    // Implement the required method to return a mock response
    public HTTPResponse respond(HTTPRequest req) {
        // Create a new HTTP response object
        HttpResponse response = new HttpResponse();
        
        // Set the mock response status code and body (JSON format)
        response.setStatusCode(200);
        String jsonResponse = '{"animal":{"id":1,"name":"chicken","eats":"chicken food","says":"cluck cluck"}}'; // Simulate the response
        response.setBody(jsonResponse);
        
        return response;
    }
}