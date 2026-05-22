@IsTest
public class BillingCalloutServiceMock implements WebServiceMock {
    private final String responseStatus;
    private final Boolean throwCalloutException;

    public static BillingServiceProxy.project lastProject;

    /**
     * Creates a default success SOAP mock response.
     */
    public BillingCalloutServiceMock() {
        this('OK', false);
    }

    /**
     * Creates a mock that returns the provided billing status.
     */
    public BillingCalloutServiceMock(String responseStatus) {
        this(responseStatus, false);
    }

    /**
     * Creates a mock that throws a CalloutException.
     */
    public BillingCalloutServiceMock(Boolean throwCalloutException, String message) {
        this(message, throwCalloutException);
    }

    private BillingCalloutServiceMock(String responseStatus, Boolean throwCalloutException) {
        this.responseStatus = responseStatus;
        this.throwCalloutException = throwCalloutException;
    }

    public void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNamespace,
        String responseName,
        String responseType
    ) {
        if (throwCalloutException) {
            throw new CalloutException(responseStatus);
        }

        BillingServiceProxy.billProjectRequest_element requestElement =
            (BillingServiceProxy.billProjectRequest_element) request;
        lastProject = requestElement.project;

        BillingServiceProxy.billProjectResponse_element responseElement =
            new BillingServiceProxy.billProjectResponse_element();
        responseElement.status = responseStatus;
        response.put('response_x', responseElement);
    }
}
