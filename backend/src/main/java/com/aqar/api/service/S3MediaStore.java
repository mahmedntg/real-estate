package com.aqar.api.service;

import java.io.InputStream;
import java.net.URI;
import com.aqar.api.config.AqarProperties;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

/**
 * Stores listing media as objects in an S3-compatible bucket.
 *
 * <p>Objects are written under their generated file name at the bucket root, and their public URL is
 * built from the configured public base so browsers can load them without going through the API.
 *
 * @author Mohamed Sayed
 */
public class S3MediaStore {

    private static final String DEFAULT_REGION = "us-east-1";

    private final S3Client client;
    private final String bucket;
    private final String publicBase;

    /**
     * Creates a store around an existing client, mainly for tests.
     *
     * @param client S3 client used for uploads and deletions
     * @param bucket bucket holding the media objects
     * @param publicBase base URL under which the bucket objects are publicly reachable
     */
    S3MediaStore(final S3Client client, final String bucket, final String publicBase) {
        this.client = client;
        this.bucket = bucket;
        this.publicBase = stripTrailingSlash(publicBase);
    }

    /**
     * Builds the store when the bucket name and access key are configured.
     *
     * @param config S3 settings from the application configuration
     * @return the store, or null when S3 storage is not configured
     */
    public static S3MediaStore create(final AqarProperties.S3 config) {
        if (config == null || isBlank(config.bucket()) || isBlank(config.accessKey())) {
            return null;
        }
        String region = isBlank(config.region()) ? DEFAULT_REGION : config.region();
        S3ClientBuilder builder = S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(config.accessKey(), config.secretKey())))
                .httpClient(UrlConnectionHttpClient.create());
        String endpoint = config.endpoint();
        if (!isBlank(endpoint)) {
            builder.endpointOverride(URI.create(endpoint)).forcePathStyle(true);
        }
        String publicBase = isBlank(config.publicUrl())
                ? defaultPublicBase(config.bucket(), region, endpoint)
                : config.publicUrl();
        return new S3MediaStore(builder.build(), config.bucket(), publicBase);
    }

    /**
     * Uploads one media object.
     *
     * @param filename generated media file name used as the object key
     * @param contentType MIME type stored with the object
     * @param size exact number of bytes in the body
     * @param body content of the uploaded file
     */
    void put(final String filename, final String contentType, final long size, final InputStream body) {
        client.putObject(PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(filename)
                        .contentType(contentType)
                        .build(),
                RequestBody.fromInputStream(body, size));
    }

    /**
     * Deletes one media object.
     *
     * @param filename object key to delete
     */
    void delete(final String filename) {
        client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(filename).build());
    }

    /**
     * Builds the public URL of a stored object.
     *
     * @param filename object key
     * @return absolute URL under the configured public base
     */
    String url(final String filename) {
        return publicBase + "/" + filename;
    }

    /**
     * Returns the public base under which objects are reachable.
     *
     * @return public base URL without a trailing slash
     */
    String publicBase() {
        return publicBase;
    }

    /**
     * Reports whether a configuration value is absent or blank.
     *
     * @param value configuration value
     * @return true when the value is null or blanks
     */
    private static boolean isBlank(final String value) {
        return value == null || value.isBlank();
    }

    /**
     * Derives the public base for the configured service.
     *
     * @param bucket bucket holding the objects
     * @param region AWS region of the bucket
     * @param endpoint custom endpoint, blank when targeting AWS S3
     * @return base URL without a trailing slash
     */
    private static String defaultPublicBase(final String bucket, final String region, final String endpoint) {
        if (!isBlank(endpoint)) {
            return stripTrailingSlash(endpoint) + "/" + bucket;
        }
        return "https://" + bucket + ".s3." + region + ".amazonaws.com";
    }

    /**
     * Removes a single trailing slash from a URL.
     *
     * @param value URL that may end with a slash
     * @return URL without a trailing slash
     */
    private static String stripTrailingSlash(final String value) {
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }
}
