//
//  SKYDefineCreationAccessOperationTests.m
//  SKYKit
//
//  Copyright 2015 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <SKYKit/SKYKit.h>

SpecBegin(SKYDefineCreationAccessOperation)

    describe(@"Define Creation Access Operation", ^{
        NSString *apiKey = @"CORRECT_KEY";
        NSString *currentUserID = @"CORRECT_USER_ID";
        NSString *token = @"CORRECT_TOKEN";

        NSString *developerRoleName = @"Developer";
        NSString *testerRoleName = @"Tester";

        NSString *sourceCodeRecordType = @"SourceCode";

        SKYRole *developerRole = [SKYRole roleWithName:developerRoleName];
        SKYRole *testerRole = [SKYRole roleWithName:testerRoleName];

        __block SKYContainer *container;

        beforeEach(^{
            container = [[SKYContainer alloc] init];
            [container configureWithAPIKey:apiKey];
            [container updateWithUserRecordID:currentUserID
                                  accessToken:[[SKYAccessToken alloc] initWithTokenString:token]];
        });

        it(@"should create SKYRequest correctly", ^{
            SKYDefineCreationAccessOperation *operation = [SKYDefineCreationAccessOperation
                operationWithRecordType:sourceCodeRecordType
                                  roles:@[ developerRole, testerRole ]];
            [operation setContainer:container];
            [operation prepareForRequest];

            SKYRequest *request = operation.request;
            expect(request.action).to.equal(@"schema:access");
            expect(request.accessToken.tokenString).to.equal(token);

            NSString *recordTypePayload = [request.payload objectForKey:@"type"];
            NSArray<NSString *> *accessRolesPayload =
                [request.payload objectForKey:@"create_roles"];

            expect(recordTypePayload).to.equal(sourceCodeRecordType);
            expect(accessRolesPayload).to.haveACountOf(2);
            expect(accessRolesPayload).to.contain(@"Developer");
            expect(accessRolesPayload).to.contain(@"Tester");
        });

        it(@"should handle success response correctly", ^{
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *response = @{
                        @"result" : @{
                            @"type" : sourceCodeRecordType,
                            @"roles" : @[ developerRoleName, testerRoleName ]
                        }
                    };
                    return [OHHTTPStubsResponse responseWithJSONObject:response
                                                            statusCode:200
                                                               headers:nil];
                }];

            SKYDefineCreationAccessOperation *operation = [SKYDefineCreationAccessOperation
                operationWithRecordType:sourceCodeRecordType
                                  roles:@[ developerRole, testerRole ]];
            [operation setContainer:container];

            waitUntil(^(DoneCallback done) {
                operation.defineCreationAccessCompletionBlock =
                    ^(NSString *recordType, NSArray<SKYRole *> *roles, NSError *error) {
                        expect(recordType).to.equal(sourceCodeRecordType);
                        expect(roles).to.haveACountOf(2);
                        expect(roles).to.contain(developerRole);
                        expect(roles).to.contain(testerRole);
                        expect(error).to.beNil();

                        done();
                    };

                [container addOperation:operation];
            });
        });

        afterEach(^{
            [OHHTTPStubs removeAllStubs];
        });
    });

SpecEnd