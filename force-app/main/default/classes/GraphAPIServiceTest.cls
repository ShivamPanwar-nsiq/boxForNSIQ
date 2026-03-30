/**
 * @description Test class for GraphAPIService covering all API methods and exception handling.
 */
@isTest
private class GraphAPIServiceTest {

    /**
     * @description Mock implementation of HttpCalloutMock used to simulate Graph API responses.
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        private String status;

        /**
         * @description Constructor for the mock response generator.
         * @param statusCode The HTTP status code to return.
         * @param body The HTTP response body to return.
         * @param status The HTTP status text (e.g., "OK", "Bad Request").
         */
        public MockHttpResponseGenerator(Integer statusCode, String body, String status) {
            this.statusCode = statusCode;
            this.body = body;
            this.status = status;
        }

        /**
         * @description Creates and returns a mocked HttpResponse for the provided request.
         * @param req The HttpRequest being simulated.
         * @return A mocked HttpResponse with predefined body, status, and statusCode.
         */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            res.setStatus(status);
            return res;
        }
    }

    /**
     * @description Creates a mock list response that simulates a paginated Graph API result.
     * @return A JSON string representing a typical list response with @odata.nextLink.
     */
    private static String createMockListResponse() {
        return '{"value":[{"id":"item1","name":"Test Item","webUrl":"https://example.com","size":"1024"}],"@odata.nextLink":"https://graph.microsoft.com/v1.0/next"}';
    }

    /**
     * @description Creates a mock file response used for upload tests.
     * @return A JSON string containing file metadata.
     */
    private static String createMockFileResponse() {
        return '{"id":"file1","name":"TestFile.txt","webUrl":"https://example.com/file","size":"2048"}';
    }
    
    @isTest
    static void testGetSites() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockListResponse(), 
            'OK'
        ));

        User testUser = createTestUser();

        System.runAs(testUser) {
            Test.startTest();
            GraphAPIService.FromJSON result = GraphAPIService.getSites();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.value.size(), 'Should return one item');
            System.assertEquals('item1', result.value[0].id, 'Item ID should match');
            System.assertEquals('https://graph.microsoft.com/v1.0/next', result.nextUrl, 'Next URL should be set');
        }
    }    

    private static User createTestUser() {
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
    }    @isTest
    static void testGetDrives() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockListResponse(), 
            'OK'
        ));
        
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        System.runAs(testUser) {
            Test.startTest();
            GraphAPIService.FromJSON result = GraphAPIService.getDrives('site1');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.value.size(), 'Should return one drive');
        }
    }    
    @isTest
    static void testGetFolders() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockListResponse(), 
            'OK'
        ));
        
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        System.runAs(testUser) {
            Test.startTest();
            GraphAPIService.FromJSON result = GraphAPIService.getFolders('site1', 'drive1');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.value.size(), 'Should return one folder');
        }
    }    
    @isTest
    static void testGetFiles() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockListResponse(), 
            'OK'
        ));
        
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        System.runAs(testUser) {
            Test.startTest();
            GraphAPIService.FromJSON result = GraphAPIService.getFiles('folder1', 'site1', 'drive1');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.value.size(), 'Should return one file');
        }
    }    
    @isTest
    static void testCreateUploadSession() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        String mockResponse = '{"uploadUrl":"https://example.com/upload"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            mockResponse, 
            'OK'
        ));
        
        System.runAs(testUser) {
            Test.startTest();
            String result = GraphAPIService.createUploadSession('site1', 'drive1', 'folder1', 'test.txt');
            Test.stopTest();
            
            System.assertEquals(mockResponse, result, 'Should return the upload URL response');
        }
    }    
    @isTest
    static void testCreateUploadSessionError() {

        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            400, 
            '{"error":{"message":"Bad Request"}}', 
            'Bad Request'
        ));
        
        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.createUploadSession('site1', 'drive1', 'folder1', 'test.txt');
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testUploadChunk() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        String mockResponse = '{"id":"file1","name":"test.txt"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            mockResponse, 
            'OK'
        ));
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        System.runAs(testUser) {
            Test.startTest();
            String result = GraphAPIService.uploadChunk('https://example.com/upload', base64Data, 0, 16, 17);
            Test.stopTest();
            
            System.assertEquals(mockResponse, result, 'Should return the upload response');
        }
    }    
    @isTest
    static void testUploadChunkError() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            400, 
            '{"error":{"message":"Bad Request"}}', 
            'Bad Request'
        ));
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        
        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.uploadChunk('https://example.com/upload', base64Data, 0, 16, 17);
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testUploadFileToSharePoint() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockFileResponse(), 
            'OK'
        ));
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        System.runAs(testUser) {
            Test.startTest();
            String result = GraphAPIService.uploadFileToSharePoint('site1', 'drive1', 'folder1', 'test.txt', 'text/plain', base64Data);
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }    
    @isTest
    static void testUploadFileToSharePointSizeLimit() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            413,
            '{"error":{"message":"Request entity too large"}}',
            'Request Entity Too Large'
        ));

        System.runAs(testUser) {
            Test.startTest();
            try {
                String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
                
                GraphAPIService.uploadFileToSharePoint('site1', 'drive1', 'folder1', 'large.txt', 'text/plain', base64Data);
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testCreateFolderInSharePoint() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            201, 
            '{"id":"folder1","name":"TestFolder"}', 
            'Created'
        ));

        System.runAs(testUser) {
            Test.startTest();
            String result = GraphAPIService.createFolderInSharePoint('site1', 'drive1', 'root', 'TestFolder');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }    
    @isTest
    static void testCreateFolderInSharePointError() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            400, 
            '{"error":{"message":"Bad Request"}}', 
            'Bad Request'
        ));

        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.createFolderInSharePoint('site1', 'drive1', 'root', 'TestFolder');
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testDeleteFileFromSharePoint() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            204, 
            '', 
            'No Content'
        ));

        System.runAs(testUser) {
            Test.startTest();
            Boolean result = GraphAPIService.deleteFileFromSharePoint('site1', 'drive1', 'file1');
            Test.stopTest();
            
            System.assertEquals(true, result, 'Should return true for successful deletion');
        }
    }    
    @isTest
    static void testDeleteFileFromSharePointError() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            404, 
            '{"error":{"message":"Not Found"}}', 
            'Not Found'
        ));

        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.deleteFileFromSharePoint('site1', 'drive1', 'file1');
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testLoadMoreSendRequest() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            200, 
            createMockListResponse(), 
            'OK'
        ));

        System.runAs(testUser) {
            Test.startTest();
            GraphAPIService.FromJSON result = GraphAPIService.loadMoreSendRequest('https://graph.microsoft.com/v1.0/sites?$skiptoken=token');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(1, result.value.size(), 'Should return one item');
        }
    }    
    @isTest
    static void testLoadMoreSendRequestError() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            400, 
            '{"error":{"message":"Bad Request"}}', 
            'Bad Request'
        ));

        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.loadMoreSendRequest('https://graph.microsoft.com/v1.0/sites?$skiptoken=token');
                System.assert(false, 'Should have thrown an exception');
            } catch (CalloutException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }

    }    
    @isTest
    static void testSendRequestError() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'Test',
            Email = 'test@test.com',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(
            400, 
            '{"error":{"message":"Bad Request"}}', 
            'Bad Request'
        ));

        System.runAs(testUser) {
            Test.startTest();
            try {
                GraphAPIService.getSites();
                System.assert(false, 'Should have thrown an exception');
            } catch (CalloutException e) {
                System.assert(true, 'Exception was thrown as expected');
            }
            Test.stopTest();
        }
    }
}