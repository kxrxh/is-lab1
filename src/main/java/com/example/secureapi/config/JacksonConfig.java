package com.example.secureapi.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

@Configuration
public class JacksonConfig {

    @Bean
    @Primary
    public ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
        ObjectMapper objectMapper = builder.build();

        // Enable HTML escaping to prevent XSS attacks
        // This will automatically escape dangerous HTML characters in all JSON responses
        objectMapper.configure(
            com.fasterxml.jackson.core.json.JsonWriteFeature.ESCAPE_NON_ASCII.mappedFeature(), true
        );

        objectMapper.getFactory().setCharacterEscapes(new HtmlEscapingCharacterEscapes());

        return objectMapper;
    }

    /**
     * Static inner class for HTML character escaping to prevent XSS attacks.
     * This class doesn't need access to the outer class instance, so it's static
     * to avoid holding unnecessary references and improve performance.
     */
    private static class HtmlEscapingCharacterEscapes extends com.fasterxml.jackson.core.io.CharacterEscapes {
        @Override
        public int[] getEscapeCodesForAscii() {
            int[] escapes = standardAsciiEscapesForJSON();
            escapes['<'] = com.fasterxml.jackson.core.io.CharacterEscapes.ESCAPE_STANDARD;
            escapes['>'] = com.fasterxml.jackson.core.io.CharacterEscapes.ESCAPE_STANDARD;
            escapes['&'] = com.fasterxml.jackson.core.io.CharacterEscapes.ESCAPE_STANDARD;
            escapes['\''] = com.fasterxml.jackson.core.io.CharacterEscapes.ESCAPE_STANDARD;
            escapes['\"'] = com.fasterxml.jackson.core.io.CharacterEscapes.ESCAPE_STANDARD;
            return escapes;
        }

        @Override
        public com.fasterxml.jackson.core.SerializableString getEscapeSequence(int ch) {
            return null;
        }
    }
}
