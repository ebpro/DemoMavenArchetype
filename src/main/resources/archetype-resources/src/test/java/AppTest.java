package $package;

import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Unit test for simple App.
 */
@Slf4j
class AppTest {

    @Test
    void addCorrect() {
        assertEquals(5, new App().add(3, 2));
    }

    @Test
    void addCheckException1() {
        assertThrows(NumberFormatException.class, () -> new App().add(-3, 2));
    }

    @Test
    void addCheckException2() {
        assertThrows(NumberFormatException.class, () -> new App().add(3, -2));
    }

}
