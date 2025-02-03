public class AnimalLocator {
    public static String getAnimalNameById(Integer animalId) {
        String url = 'https://th-apex-http-callout.herokuapp.com/animals/' + String.valueOf(animalId);
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(url);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        HttpResponse response = http.send(request);
        String strResp = '';
        
        if (response.getStatusCode() == 200) {
            // Parse the response body to get the animal name
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Cast the values in the 'animals' key as a list
            Map<string,object> animals = (map<string,object>) results.get('animal');
            
            strResp = string.valueof(animals.get('name'));
            
        } 
        return strResp;
    }
}