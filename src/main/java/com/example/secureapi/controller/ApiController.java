package com.example.secureapi.controller;

import com.example.secureapi.dto.PostDto;
import com.example.secureapi.entity.Post;
import com.example.secureapi.entity.User;
import com.example.secureapi.repository.PostRepository;
import com.example.secureapi.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class ApiController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PostRepository postRepository;

    @GetMapping("/data")
    public ResponseEntity<?> getData() {
        // Get current authenticated user
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        User currentUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Return user data and list of all users (sanitized)
        List<User> users = userRepository.findAll();
        List<String> usernames = users.stream()
                .map(User::getUsername)
                .collect(Collectors.toList());

        return ResponseEntity.ok(new DataResponse(currentUser.getName(), usernames));
    }

    @GetMapping("/posts")
    public ResponseEntity<?> getPosts() {
        List<Post> posts = postRepository.findAllByOrderByCreatedAtDesc();

        List<PostDto> postDtos = posts.stream()
                .map(post -> new PostDto(
                        post.getId(),
                        escapeHtml(post.getTitle()),
                        escapeHtml(post.getContent()),
                        escapeHtml(post.getAuthor().getName()),
                        post.getCreatedAt(),
                        post.getUpdatedAt()
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(postDtos);
    }

    @PostMapping("/posts")
    public ResponseEntity<?> createPost(@Valid @RequestBody PostDto postDto) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        User author = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Post post = new Post(postDto.getTitle(), postDto.getContent(), author);
        Post savedPost = postRepository.save(post);

        PostDto responseDto = new PostDto(
                savedPost.getId(),
                escapeHtml(savedPost.getTitle()),
                escapeHtml(savedPost.getContent()),
                escapeHtml(savedPost.getAuthor().getName()),
                savedPost.getCreatedAt(),
                savedPost.getUpdatedAt()
        );

        return ResponseEntity.ok(responseDto);
    }

    // XSS protection: Simple HTML escaping
    private String escapeHtml(String text) {
        if (text == null) return null;
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#x27;");
    }

    // Inner class for data response
    public static class DataResponse {
        private String currentUser;
        private List<String> allUsers;

        public DataResponse(String currentUser, List<String> allUsers) {
            this.currentUser = currentUser;
            this.allUsers = allUsers == null ? null : List.copyOf(allUsers);
        }

        public String getCurrentUser() {
            return currentUser;
        }

        public void setCurrentUser(String currentUser) {
            this.currentUser = currentUser;
        }

        public List<String> getAllUsers() {
            return allUsers == null ? null : List.copyOf(allUsers);
        }

        public void setAllUsers(List<String> allUsers) {
            this.allUsers = allUsers == null ? null : List.copyOf(allUsers);
        }
    }
}
