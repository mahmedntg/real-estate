package com.aqar.api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import java.io.ByteArrayInputStream;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import com.aqar.api.config.AqarProperties;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

class S3MediaStoreTest {

    @Test
    void uploadsAndDeletesObjectsByFileName() {
        S3Client client = mock(S3Client.class);
        S3MediaStore store = new S3MediaStore(client, "aqar-media", "https://cdn.example.com/aqar/");
        byte[] bytes = {1, 2, 3};

        store.put("photo.jpg", "image/jpeg", bytes.length, new ByteArrayInputStream(bytes));

        ArgumentCaptor<PutObjectRequest> upload = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(client).putObject(upload.capture(), any(RequestBody.class));
        assertEquals("aqar-media", upload.getValue().bucket());
        assertEquals("photo.jpg", upload.getValue().key());
        assertEquals("image/jpeg", upload.getValue().contentType());
        assertEquals("https://cdn.example.com/aqar/photo.jpg", store.url("photo.jpg"));

        store.delete("photo.jpg");

        ArgumentCaptor<DeleteObjectRequest> deletion = ArgumentCaptor.forClass(DeleteObjectRequest.class);
        verify(client).deleteObject(deletion.capture());
        assertEquals("aqar-media", deletion.getValue().bucket());
        assertEquals("photo.jpg", deletion.getValue().key());
    }

    @Test
    void staysDisabledWithoutBucketOrCredentials() {
        assertNull(S3MediaStore.create(null));
        assertNull(S3MediaStore.create(new AqarProperties.S3("", "us-east-1", "", "", "", "")));
        assertNull(S3MediaStore.create(new AqarProperties.S3("aqar-media", "us-east-1", "", "", "", "")));
    }

    @Test
    void derivesPublicUrlsForAwsAndCustomEndpoints() {
        S3MediaStore aws = S3MediaStore.create(
                new AqarProperties.S3("aqar-media", "eu-west-1", "", "", "key", "secret"));
        assertNotNull(aws);
        assertEquals("https://aqar-media.s3.eu-west-1.amazonaws.com/video.mp4", aws.url("video.mp4"));

        S3MediaStore custom = S3MediaStore.create(new AqarProperties.S3(
                "aqar-media", "auto", "https://account.r2.cloudflarestorage.com", "https://cdn.aqar.app/", "key",
                "secret"));
        assertNotNull(custom);
        assertEquals("https://cdn.aqar.app/video.mp4", custom.url("video.mp4"));
    }
}
