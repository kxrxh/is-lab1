package com.example.secureapi.config;

import com.example.secureapi.entity.Post;
import com.example.secureapi.entity.User;
import com.example.secureapi.repository.PostRepository;
import com.example.secureapi.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Create sample users
        if (userRepository.count() == 0) {
            User user1 = new User("john_doe", passwordEncoder.encode("password123"), "John Doe");
            User user2 = new User("jane_smith", passwordEncoder.encode("password123"), "Jane Smith");
            User user3 = new User("admin", passwordEncoder.encode("admin123"), "Administrator");

            userRepository.save(user1);
            userRepository.save(user2);
            userRepository.save(user3);

            // Create sample posts
            Post post1 = new Post("Welcome to Secure API", "This is a sample post demonstrating the secure API functionality.", user1);
            Post post2 = new Post("Security Best Practices", "Always validate input, use parameterized queries, and implement proper authentication.", user2);
            Post post3 = new Post("Getting Started", "To use this API, first register an account, then login to get a JWT token.", user3);

            postRepository.save(post1);
            postRepository.save(post2);
            postRepository.save(post3);

            System.out.println("Sample data initialized successfully!");
        }
    }
}
