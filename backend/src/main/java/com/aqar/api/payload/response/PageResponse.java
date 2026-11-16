package com.aqar.api.payload.response;

import java.util.List;
import org.springframework.data.domain.Page;
import lombok.Getter;
import lombok.Setter;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.annotation.JsonNaming;

/**
 * Generic paging envelope returned by the list endpoints.
 *
 * <p>Repeats the Spring Data {@link Page} metadata together with the already mapped items so clients
 * can render paging controls without knowing the persistence layer.
 *
 * @param <T> type of the mapped items
 * @author Mohamed Sayed
 */
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PageResponse<T> {

    private List<T> items;

    private int page;

    private int size;

    private long totalElements;

    private int totalPages;

    private boolean hasNext;

    /**
     * Wraps the mapped items of a source page into this envelope.
     *
     * @param source the page supplying the paging metadata
     * @param items the items already mapped for the current page
     * @param <T> type of the mapped items
     * @return the populated paging envelope
     */
    public static <T> PageResponse<T> of(final Page<?> source, final List<T> items) {
        PageResponse<T> response = new PageResponse<>();
        response.setItems(items);
        response.setPage(source.getNumber());
        response.setSize(source.getSize());
        response.setTotalElements(source.getTotalElements());
        response.setTotalPages(source.getTotalPages());
        response.setHasNext(source.hasNext());
        return response;
    }
}
