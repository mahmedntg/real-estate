package com.aqar.api.exception;

import org.springframework.http.HttpStatus;

/**
 * Runtime exception carrying the HTTP status, problem title and detail of a rejected API request.
 *
 * <p>Instances are rendered as Problem Details responses by the global exception handler.
 *
 * @author Mohamed Sayed
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String title;

    /**
     * Creates an exception describing a rejected request.
     *
     * @param status the HTTP status to report
     * @param title the problem title to report
     * @param detail the human readable detail, also used as the exception message
     */
    public ApiException(final HttpStatus status, final String title, final String detail) {
        super(detail);
        this.status = status;
        this.title = title;
    }

    public static ApiException notFound(final String detail) {
        return new ApiException(HttpStatus.NOT_FOUND, "Not found", detail);
    }

    public static ApiException forbidden(final String detail) {
        return new ApiException(HttpStatus.FORBIDDEN, "Forbidden", detail);
    }

    public static ApiException badRequest(final String title, final String detail) {
        return new ApiException(HttpStatus.BAD_REQUEST, title, detail);
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getTitle() {
        return title;
    }
}
