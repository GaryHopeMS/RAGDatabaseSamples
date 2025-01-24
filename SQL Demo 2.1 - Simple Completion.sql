CREATE MASTER KEY

CREATE DATABASE SCOPED CREDENTIAL [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions]
	WITH IDENTITY = 'Managed Identity',
		SECRET = '{"resourceid": "https://cognitiveservices.azure.com" }';

DECLARE @Prompt NVARCHAR(MAX) = 'when was the latest US president inagurated, just provide the date'
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
									 {"role":"user","content":"'+ @Prompt +'"}
									 ]}'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @ResultCode INT, @Response NVARCHAR(max);
EXEC @ResultCode = sp_invoke_external_rest_endpoint
    @URL = @url,
    @method = 'POST',
    @credential = [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions],
    @payload = @Payload,
    @timeout = 230,
    @Response = @response output;
SELECT @ResultCode AS ReturnCode, @response as Response,JSON_QUERY(@response, '$.result.choices[0].message') AS ResponseText ;
SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseContent 

CREATE or ALTER PROCEDURE [get_completion]
@payload NVARCHAR(max),
@response NVARCHAR(max) OUTPUT
AS
BEGIN
	DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
	DECLARE @ResultCode INT
	EXEC @ResultCode = sp_invoke_external_rest_endpoint
		@URL = @url,
		@method = 'POST',
		@credential = [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions],
		@payload = @Payload,
		@timeout = 230,
		@response= @response output;
END;

DECLARE @UserPrompt NVARCHAR(MAX) = 'when was this model last updated and what is the model called?'
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseContent 


DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the biggest mamal?'
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseContent 


--- /////////////////////////////////////////////////                              ---
--- Perform Completion Against Azure Open AI Endpoint without conversation context ---

DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the smalest?'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseContent 