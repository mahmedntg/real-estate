package com.aqar.api.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import com.aqar.api.domain.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository for Message entities, exposing paged conversation reads, unread
 * message counting and bulk marking of messages as read.
 *
 * @author Mohamed Sayed
 */
public interface MessageRepository extends JpaRepository<Message, UUID> {

    @EntityGraph(attributePaths = "sender")
    Page<Message> findByConversationId(UUID conversationId, Pageable pageable);

    @EntityGraph(attributePaths = "sender")
    Optional<Message> findTopByConversationIdOrderByCreatedAtDesc(UUID conversationId);

    @Query("""
            select m.conversation.id, count(m)
            from Message m
            where m.conversation.id in :conversationIds
              and m.sender.id <> :userId
              and m.readFlag = false
            group by m.conversation.id
            """)
    List<Object[]> countUnread(@Param("conversationIds") Collection<UUID> conversationIds,
                               @Param("userId") UUID userId);

    @Modifying(clearAutomatically = true)
    @Query("""
            update Message m
            set m.readFlag = true
            where m.conversation.id = :conversationId
              and m.sender.id <> :userId
              and m.readFlag = false
            """)
    int markRead(@Param("conversationId") UUID conversationId, @Param("userId") UUID userId);
}
