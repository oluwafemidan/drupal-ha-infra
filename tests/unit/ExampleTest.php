<?php

namespace Drupal\Tests\unit;

use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase {
    
    public function testBasicExample() {
        $this->assertTrue(true, 'Basic test should pass');
    }
    
    public function testStringOperations() {
        $string = 'Drupal';
        $this->assertEquals(6, strlen($string));
    }
}
