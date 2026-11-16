package com.aqar.api.exception;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

/**
 * Global REST exception handler that renders failures as Problem Details JSON responses.
 *
 * <p>Each handler keeps a stable title and status so the Flutter client can branch on them.
 *
 * @author Mohamed Sayed
 */
@RestControllerAdvice
public class ApiExceptionHandler {

    /**
     * Renders an application exception with the status, title and detail it carries.
     *
     * @param ex the application exception raised by a service
     * @return response carrying the matching problem detail
     */
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ProblemDetail> handleApiException(final ApiException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(ex.getStatus(), ex.getMessage());
        problem.setTitle(ex.getTitle());
        return ResponseEntity.status(ex.getStatus()).body(problem);
    }

    /**
     * Renders bean validation failures as a 400 problem listing every rejected field and its message.
     *
     * @param ex the validation failure raised while binding the request body
     * @return response carrying the validation problem detail
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(final MethodArgumentNotValidException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Request validation failed");
        problem.setTitle("Validation failed");
        List<Map<String, String>> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", Objects.requireNonNullElse(error.getDefaultMessage(), "invalid value")))
                .toList();
        problem.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(problem);
    }

    /**
     * Renders a failed parameter conversion as a 400 problem that names the offending parameter.
     *
     * @param ex the type mismatch raised while binding a path or query parameter
     * @return response carrying the invalid parameter problem detail
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ProblemDetail> handleTypeMismatch(final MethodArgumentTypeMismatchException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "Invalid value for parameter '" + ex.getName() + "'");
        problem.setTitle("Invalid parameter");
        return ResponseEntity.badRequest().body(problem);
    }

    /**
     * Renders a missing or unparsable JSON request body as a 400 problem.
     *
     * @param ex the body parsing failure
     * @return response carrying the malformed request problem detail
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ProblemDetail> handleUnreadableBody(final HttpMessageNotReadableException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "The request body is missing or malformed");
        problem.setTitle("Malformed request");
        return ResponseEntity.badRequest().body(problem);
    }

    /**
     * Renders an oversize multipart upload as a 413 problem that states the per-file limit.
     *
     * @param ex the upload size rejection raised by the multipart resolver
     * @return response carrying the upload too large problem detail
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ProblemDetail> handleUploadTooLarge(final MaxUploadSizeExceededException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.PAYLOAD_TOO_LARGE, "Uploaded files exceed the 8 MB per-file limit");
        problem.setTitle("Upload too large");
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(problem);
    }

    /**
     * Renders a database constraint violation as a 409 problem instead of leaking persistence details.
     *
     * @param ex the integrity violation raised while flushing a transaction
     * @return response carrying the conflict problem detail
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ProblemDetail> handleConflict(final DataIntegrityViolationException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT, "The request conflicts with existing data");
        problem.setTitle("Conflict");
        return ResponseEntity.status(HttpStatus.CONFLICT).body(problem);
    }
}
