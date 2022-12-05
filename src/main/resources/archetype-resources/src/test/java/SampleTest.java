package $package;


import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.*;

/**
 * Unit test for simple App.
 */
@Slf4j
class SampleTest {
    @BeforeAll
    static void init() {
        log.info("Once before all tests.");
    }

    @AfterAll
    static void close() {
        log.info("Once after all tests.");
    }

    @BeforeEach
    void prepare() {
        log.info("Before each test.");
    }

    @AfterEach
    void end() {
        log.info("After each test.");
    }

    @Test
        //@Disable
    void shouldAnswerWithTrue() {
        //Assumption to check that tests condition are ok (optional).
        //Notice the static import.
        assumeTrue(10 < 100);

        assertTrue(true);
    }

    @Test
    void checkException() {
        assertThrows(ArithmeticException.class, () -> {
            int x = 3 / 0;
        });
    }

}
