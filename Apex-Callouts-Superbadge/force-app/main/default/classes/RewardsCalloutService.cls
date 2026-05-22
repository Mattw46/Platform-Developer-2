public class RewardsCalloutService {
    public static Integer submitUsersForRewardCallout(String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:IntegrationSB__BalancedLiving/rewards');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse res;
        Integer statusCode;
        try {
            res = http.send(req);
            statusCode = res.getStatusCode();
        } catch (Exception e) {
            statusCode = 500; // Internal Server Error
        }
        return statusCode;
    }
}