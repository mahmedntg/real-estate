package com.aqar.api.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;
import jakarta.annotation.PostConstruct;
import com.aqar.api.config.AqarProperties;
import com.aqar.api.domain.Property;
import com.aqar.api.domain.PropertyImage;
import com.aqar.api.payload.model.ImageView;
import com.aqar.api.payload.model.VideoView;
import com.aqar.api.exception.ApiException;
import com.aqar.api.repository.PropertyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Stores and serves the images and the single video attached to a listing.
 *
 * <p>Files are written under the configured media directory with generated UUID names, images are
 * limited to 8 MB and videos to 50 MB, and only managed file names are ever read or deleted.
 *
 * @author Mohamed Sayed
 */
@Service
public class MediaService {

    private static final Logger LOGGER = LoggerFactory.getLogger(MediaService.class);
    private static final int MAX_IMAGES_PER_PROPERTY = 8;
    private static final long MAX_FILE_BYTES = 8L * 1024 * 1024;
    private static final long MAX_VIDEO_BYTES = 50L * 1024 * 1024;
    private static final Pattern MANAGED_FILENAME = Pattern.compile(
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(jpg|png|webp)");
    private static final Pattern MANAGED_VIDEO_FILENAME = Pattern.compile(
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(mp4|webm|mov)");
    private static final String MEDIA_PREFIX = "/media/";

    private final Path root;
    private final PropertyRepository propertyRepository;

    /**
     * Creates the service and resolves the absolute media directory.
     *
     * @param properties application configuration holding the media directory
     * @param propertyRepository repository used to load and store listings
     */
    public MediaService(final AqarProperties properties, final PropertyRepository propertyRepository) {
        this.root = properties.media().dir().toAbsolutePath().normalize();
        this.propertyRepository = propertyRepository;
    }

    /**
     * Creates the media directory when it does not exist yet.
     *
     * @throws IOException when the directory cannot be created
     */
    @PostConstruct
    void init() throws IOException {
        Files.createDirectories(root);
    }

    /**
     * Stores the uploaded images for a listing and appends them after the existing images.
     *
     * @param propertyId identifier of the listing that receives the images
     * @param actorId identifier of the user performing the upload
     * @param admin whether the caller may manage any listing
     * @param files uploaded files to store
     * @return views of the stored images
     * @throws ApiException when no file is selected, the image limit is exceeded or an image is too large
     * @throws IllegalStateException when an uploaded image cannot be written to storage
     */
    @Transactional
    public List<ImageView> upload(final UUID propertyId, final UUID actorId, final boolean admin,
                                  final List<MultipartFile> files) {
        if (files == null || files.isEmpty()) {
            throw ApiException.badRequest("No images", "Select at least one image to upload");
        }
        Property property = requireManageable(propertyId, actorId, admin);
        if (property.getImages().size() + files.size() > MAX_IMAGES_PER_PROPERTY) {
            throw ApiException.badRequest("Too many images",
                    "A listing can have at most " + MAX_IMAGES_PER_PROPERTY + " images");
        }

        int sortOrder = property.getImages().stream()
                .mapToInt(PropertyImage::getSortOrder)
                .max()
                .orElse(-1) + 1;

        List<PropertyImage> added = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file.isEmpty()) {
                throw ApiException.badRequest("Empty file", "One of the selected images is empty");
            }
            if (file.getSize() > MAX_FILE_BYTES) {
                throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "Image too large",
                        "Each image must be 8 MB or smaller");
            }

            String extension = extensionFor(file.getContentType());
            String filename = UUID.randomUUID() + "." + extension;
            try (InputStream input = file.getInputStream()) {
                Files.copy(input, root.resolve(filename));
            } catch (IOException e) {
                throw new IllegalStateException("Could not store uploaded image", e);
            }
            added.add(property.addImage(MEDIA_PREFIX + filename, sortOrder++));
        }

        propertyRepository.flush();
        return added.stream().map(this::imageView).toList();
    }

    /**
     * Detaches an image from a listing and deletes its stored file.
     *
     * @param propertyId identifier of the listing holding the image
     * @param imageId identifier of the image to remove
     * @param actorId identifier of the user performing the removal
     * @param admin whether the caller may manage any listing
     */
    @Transactional
    public void delete(final UUID propertyId, final UUID imageId, final UUID actorId, final boolean admin) {
        Property property = requireManageable(propertyId, actorId, admin);
        PropertyImage image = property.getImages().stream()
                .filter(candidate -> candidate.getId().equals(imageId))
                .findFirst()
                .orElseThrow(() -> ApiException.notFound("Image not found"));

        property.removeImage(image);
        propertyRepository.save(property);
        deleteManagedFile(image.getUrl());
    }

    /**
     * Deletes the stored files of all images attached to a listing.
     *
     * @param property listing whose image files are removed
     */
    public void deleteManagedImages(final Property property) {
        for (PropertyImage image : property.getImages()) {
            deleteManagedFile(image.getUrl());
        }
    }

    /**
     * Stores a new video for a listing, replacing and deleting the previous one.
     *
     * @param propertyId identifier of the listing that receives the video
     * @param actorId identifier of the user performing the upload
     * @param admin whether the caller may manage any listing
     * @param file uploaded video file
     * @return view of the stored video
     * @throws ApiException when no video is selected or the video is too large
     * @throws IllegalStateException when the uploaded video cannot be written to storage
     */
    @Transactional
    public VideoView uploadVideo(final UUID propertyId, final UUID actorId, final boolean admin,
                                 final MultipartFile file) {
        final Property property = requireManageable(propertyId, actorId, admin);
        if (file == null || file.isEmpty()) {
            throw ApiException.badRequest("No video", "Select a video to upload");
        }
        if (file.getSize() > MAX_VIDEO_BYTES) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "Video too large",
                    "Videos must be 50 MB or smaller");
        }
        String extension = videoExtensionFor(file.getContentType());
        String filename = UUID.randomUUID() + "." + extension;
        try (InputStream input = file.getInputStream()) {
            Files.copy(input, root.resolve(filename));
        } catch (IOException e) {
            throw new IllegalStateException("Could not store uploaded video", e);
        }
        deleteManagedVideo(property);
        property.setVideoUrl(MEDIA_PREFIX + filename);
        propertyRepository.save(property);
        VideoView response = new VideoView();
        response.setUrl(property.getVideoUrl());
        return response;
    }

    /**
     * Maps a stored image to its identifier and serving URL.
     *
     * @param image stored image
     * @return image reference
     */
    private ImageView imageView(final PropertyImage image) {
        ImageView view = new ImageView();
        view.setId(image.getId());
        view.setUrl(image.getUrl());
        return view;
    }

    /**
     * Clears the video of a listing and deletes its stored file.
     *
     * @param propertyId identifier of the listing holding the video
     * @param actorId identifier of the user performing the removal
     * @param admin whether the caller may manage any listing
     */
    @Transactional
    public void deleteVideo(final UUID propertyId, final UUID actorId, final boolean admin) {
        Property property = requireManageable(propertyId, actorId, admin);
        deleteManagedVideo(property);
        property.setVideoUrl(null);
        propertyRepository.save(property);
    }

    /**
     * Deletes the stored video file referenced by a listing, when it is a managed file.
     *
     * @param property listing whose video file is removed
     */
    public void deleteManagedVideo(final Property property) {
        deleteManagedFile(property.getVideoUrl(), MANAGED_VIDEO_FILENAME);
    }

    /**
     * Loads a stored media file, rejecting names that are not managed and paths outside the root.
     *
     * @param filename generated media file name
     * @return the stored file as a resource
     */
    public Resource load(final String filename) {
        if (!MANAGED_FILENAME.matcher(filename).matches()
                && !MANAGED_VIDEO_FILENAME.matcher(filename).matches()) {
            throw ApiException.notFound("File not found");
        }
        Path file = root.resolve(filename).normalize();
        if (!file.startsWith(root) || !Files.isRegularFile(file)) {
            throw ApiException.notFound("File not found");
        }
        return new FileSystemResource(file);
    }

    /**
     * Resolves the media type from the file extension, defaulting to JPEG.
     *
     * @param filename media file name
     * @return media type matching the extension
     */
    public MediaType mediaType(final String filename) {
        String lower = filename.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".png")) {
            return MediaType.IMAGE_PNG;
        }
        if (lower.endsWith(".webp")) {
            return MediaType.parseMediaType("image/webp");
        }
        if (lower.endsWith(".mp4")) {
            return MediaType.parseMediaType("video/mp4");
        }
        if (lower.endsWith(".webm")) {
            return MediaType.parseMediaType("video/webm");
        }
        if (lower.endsWith(".mov")) {
            return MediaType.parseMediaType("video/quicktime");
        }
        return MediaType.IMAGE_JPEG;
    }

    /**
     * Maps a video content type to its file extension.
     *
     * @param contentType MIME type reported by the upload
     * @return file extension for the content type
     */
    private String videoExtensionFor(final String contentType) {
        if (contentType == null) {
            throw unsupportedVideo();
        }
        return switch (contentType.toLowerCase(Locale.ROOT)) {
            case "video/mp4" -> "mp4";
            case "video/webm" -> "webm";
            case "video/quicktime" -> "mov";
            default -> throw unsupportedVideo();
        };
    }

    /**
     * Builds the error reported for an unsupported video type.
     *
     * @return bad request error listing the accepted video formats
     */
    private ApiException unsupportedVideo() {
        return new ApiException(HttpStatus.BAD_REQUEST, "Unsupported video",
                "Only MP4, WebM and MOV videos are allowed");
    }

    /**
     * Maps an image content type to its file extension.
     *
     * @param contentType MIME type reported by the upload
     * @return file extension for the content type
     */
    private String extensionFor(final String contentType) {
        if (contentType == null) {
            throw unsupportedImage();
        }
        return switch (contentType.toLowerCase(Locale.ROOT)) {
            case "image/jpeg", "image/jpg" -> "jpg";
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            default -> throw unsupportedImage();
        };
    }

    /**
     * Builds the error reported for an unsupported image type.
     *
     * @return bad request error listing the accepted image formats
     */
    private ApiException unsupportedImage() {
        return new ApiException(HttpStatus.BAD_REQUEST, "Unsupported image",
                "Only JPEG, PNG and WebP images are allowed");
    }

    /**
     * Deletes a stored image file referenced by a media URL.
     *
     * @param url media URL of the image
     */
    private void deleteManagedFile(final String url) {
        deleteManagedFile(url, MANAGED_FILENAME);
    }

    /**
     * Deletes a stored file when its URL is a managed media URL for the given pattern, logging
     * deletion failures instead of failing the request.
     *
     * @param url media URL of the file
     * @param pattern pattern the generated file name must match
     */
    private void deleteManagedFile(final String url, final Pattern pattern) {
        if (url == null || !url.startsWith(MEDIA_PREFIX)) {
            return;
        }
        String filename = url.substring(MEDIA_PREFIX.length());
        if (!pattern.matcher(filename).matches()) {
            return;
        }
        try {
            Files.deleteIfExists(root.resolve(filename));
        } catch (IOException e) {
            LOGGER.warn("Could not delete media file {}", filename, e);
        }
    }

    /**
     * Loads a listing and rejects callers who are neither its owner nor an administrator.
     *
     * @param propertyId identifier of the listing
     * @param actorId identifier of the requesting user
     * @param admin whether the caller may manage any listing
     * @return the listing the caller may manage
     */
    private Property requireManageable(final UUID propertyId, final UUID actorId, final boolean admin) {
        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> ApiException.notFound("Property not found"));
        if (!admin && !property.getOwner().getId().equals(actorId)) {
            throw ApiException.forbidden("You can only manage images of your own listings");
        }
        return property;
    }
}
