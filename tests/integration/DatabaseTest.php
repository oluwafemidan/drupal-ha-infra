<?php

namespace Drupal\Tests\integration;

use PHPUnit\Framework\TestCase;
use PDO;

class DatabaseTest extends TestCase {
    
    protected $pdo;
    
    protected function setUp(): void {
        // Setup database connection for integration tests
        $dbHost = getenv('DB_HOST');
        $dbName = getenv('DB_NAME');
        $dbUser = getenv('DB_USER');
        $dbPassword = getenv('DB_PASSWORD');
        
        if (!$dbHost || !$dbName || !$dbUser) {
            $this->markTestSkipped('Database not configured for integration tests');
        }
        
        try {
            $this->pdo = new PDO(
                "mysql:host=$dbHost;dbname=$dbName", 
                $dbUser, 
                $dbPassword
            );
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            $this->markTestSkipped('Database connection failed: ' . $e->getMessage());
        }
    }
    
    public function testDatabaseConnection() {
        $this->assertInstanceOf(PDO::class, $this->pdo);
    }
    
    public function testDatabaseQuery() {
        $stmt = $this->pdo->query("SELECT 1 as test_value");
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        $this->assertEquals(1, $result['test_value']);
    }
}