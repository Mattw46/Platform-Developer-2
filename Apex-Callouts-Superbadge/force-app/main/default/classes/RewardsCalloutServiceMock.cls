@IsTest
public class RewardsCalloutServiceMock implements HttpCalloutMock {
    private final Integer statusCode;
    private final String responseBody;
    private final Boolean throwCalloutException;

    /**
     * Creates a default success response mock.
     */
    public RewardsCalloutServiceMock() {
        this(200, '{"status":"success","message":"Users submitted successfully"}', false);
    }

    /**
     * Creates a mock that returns the provided status code and body.
     *
     * @param statusCode HTTP status code to set in the mock response.
     * @param responseBody Response payload to return in the mock response.
     */
    public RewardsCalloutServiceMock(Integer statusCode, String responseBody) {
        this(statusCode, responseBody, false);
    }

    /**
     * Creates a mock that throws a CalloutException with the provided message.
     *
     * @param exceptionMessage Message to include in the thrown CalloutException.
     */
    public RewardsCalloutServiceMock(String exceptionMessage) {
        this(500, exceptionMessage, true);
    }

    private RewardsCalloutServiceMock(Integer statusCode, String responseBody, Boolean throwCalloutException) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.throwCalloutException = throwCalloutException;
    }

    /**
     * Returns a configured response or throws a configured callout exception.
        *
        * @param request Incoming HTTP request being mocked.
        * @return Configured HTTP response when exception mode is disabled.
     */
    public HttpResponse respond(HttpRequest request) {
        if (throwCalloutException) {
            throw new CalloutException(responseBody);
        }

        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setStatus(getStatusText(statusCode));
        response.setBody(responseBody);
        return response;
    }

    private static String getStatusText(Integer code) {
        if (code == 200) {
            return 'OK';
        }

        if (code == 400) {
            return 'Bad Request';
        }

        if (code == 500) {
            return 'Internal Server Error';
        }

        return 'Mocked Status';
    }
}
