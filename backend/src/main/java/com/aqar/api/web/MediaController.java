package com.aqar.api.web;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import com.aqar.api.payload.model.ImageView;
import com.aqar.api.payload.model.VideoView;
import com.aqar.api.security.CurrentUser;
import com.aqar.api.service.MediaService;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Exposes the endpoints for listing photos, listing video and stored media files.
 *
 * @author Mohamed Sayed
 */
@RestController
public class MediaController {

    private final MediaService mediaService;
    private final CurrentUser currentUser;

    /**
     * Creates the controller with its media collaborators.
     *
     * @param mediaService service storing and loading media files
     * @param currentUser resolver for the authenticated caller
     */
    public MediaController(final MediaService mediaService, final CurrentUser currentUser) {
        this.mediaService = mediaService;
        this.currentUser = currentUser;
    }

    /**
     * Uploads up to eight photos to a listing owned by the caller or an admin.
     *
     * @param id listing identifier
     * @param files photos to store
     * @return the stored images
     */
    @PostMapping(value = "/api/v1/properties/{id}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public List<ImageView> upload(@PathVariable final UUID id, @RequestPart("files") final List<MultipartFile> files) {
        return mediaService.upload(id, currentUser.requireId(), currentUser.isAdmin(), files);
    }

    /**
     * Deletes one photo from a listing owned by the caller or an admin.
     *
     * @param id listing identifier
     * @param imageId image identifier
     */
    @DeleteMapping("/api/v1/properties/{id}/images/{imageId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable final UUID id, @PathVariable final UUID imageId) {
        mediaService.delete(id, imageId, currentUser.requireId(), currentUser.isAdmin());
    }

    /**
     * Replaces the video of a listing owned by the caller or an admin.
     *
     * @param id listing identifier
     * @param file video file, at most fifty megabytes
     * @return the stored video
     */
    @PostMapping(value = "/api/v1/properties/{id}/video", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public VideoView uploadVideo(@PathVariable final UUID id, @RequestPart("file") final MultipartFile file) {
        return mediaService.uploadVideo(id, currentUser.requireId(), currentUser.isAdmin(), file);
    }

    /**
     * Removes the video of a listing owned by the caller or an admin.
     *
     * @param id listing identifier
     */
    @DeleteMapping("/api/v1/properties/{id}/video")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteVideo(@PathVariable final UUID id) {
        mediaService.deleteVideo(id, currentUser.requireId(), currentUser.isAdmin());
    }

    /**
     * Streams a stored media file, cached publicly for thirty days.
     *
     * @param filename stored file name
     * @return the file resource with its detected content type
     */
    @GetMapping("/media/{filename:.+}")
    public ResponseEntity<Resource> media(@PathVariable final String filename) {
        Resource resource = mediaService.load(filename);
        return ResponseEntity.ok()
                .contentType(mediaService.mediaType(filename))
                .cacheControl(CacheControl.maxAge(30, TimeUnit.DAYS).cachePublic())
                .body(resource);
    }
}
