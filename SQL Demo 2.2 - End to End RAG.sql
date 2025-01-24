
--- Create Chat History Table

-- DROP TABLE dbo.ChatHistory
CREATE TABLE dbo.ChatHistory (
	MessageID BIGINT IDENTITY(1,1), 
	ConversationID BIGINT NULL,
	UserPrompt NVARCHAR(MAX),
	AssistantResponse NVARCHAR(MAX),
	PromptTokens BIGINT,
	CompletionTokens BIGINT
	)

GO

--- Reset Chat History 
DELETE dbo.ChatHistory
GO

--- Call Azure Open AI with prompt and save conversation

DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the biggest mamal?'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT  
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens
INSERT dbo.ChatHistory(UserPrompt, AssistantResponse,  PromptTokens, CompletionTokens) 
	VALUES(@UserPrompt,
		JSON_VALUE(@response, '$.result.choices[0].message.content') ,
		JSON_VALUE(@response, '$.result.usage.prompt_tokens') ,
		JSON_VALUE(@response, '$.result.usage.completion_tokens')
	)

--- View Chat History
SELECT TOP(10) * FROM dbo.ChatHistory ORDER BY MessageID ASC

--- View Constucted Conversation from chat history
DECLARE @ConversationContext NVARCHAR(MAX)
SET @ConversationContext = 
		(
			SELECT * FROM (
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-1) Question : ' + UserPrompt AS MessageRow 
					FROM dbo.ChatHistory
				UNION ALL
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-2) Answer : ' + AssistantResponse AS MessageRow 
					FROM dbo.ChatHistory
				ORDER BY MessageRow Asc
			) AS Messages
			FOR XML AUTO
		)
SET @ConversationContext = 
		REPLACE(REPLACE(@ConversationContext, '<Messages MessageRow="',''),'"/>','')
SELECT @ConversationContext

--- Call Azure Open AI with prompt, using converstion history and save conversation
DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @ConversationContext NVARCHAR(MAX)
SET @ConversationContext = 
		(
			SELECT * FROM (
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-1) Question : ' + UserPrompt AS MessageRow 
					FROM dbo.ChatHistory
				UNION ALL
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-2) Answer : ' + AssistantResponse AS MessageRow 
					FROM dbo.ChatHistory
				ORDER BY MessageRow Asc
			) AS Messages
			FOR XML AUTO
		)
SET @ConversationContext = 
		REPLACE(REPLACE(@ConversationContext, '<Messages MessageRow="',''),'"/>','')
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the smalest?'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"system","content":"'+ @ConversationContext + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT 
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens
INSERT dbo.ChatHistory(UserPrompt, AssistantResponse,  PromptTokens, CompletionTokens) 
	VALUES(@UserPrompt,
		JSON_VALUE(@response, '$.result.choices[0].message.content') ,
		JSON_VALUE(@response, '$.result.usage.prompt_tokens') ,
		JSON_VALUE(@response, '$.result.usage.completion_tokens')
	)

--- ////////////////////////////////////////////////////////////////////            ---
--- Grounding completions with data

--- New Ungrounded conversation about bikes

DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the cheapest bike?'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT 
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens


--- Display the product context we want to ground our completion

DECLARE @ProductContext  VARCHAR(MAX) 
SET @ProductContext = (
	SELECT --TOP(20)
			p.[ProductID]
			,p.[Name]
			,p.ListPrice
			,p.Size
			,p.Color
			,pm.[Name] AS [ProductModel]
			,pmx.[Culture]
			,pd.[Description] as [ProductDescription]
			,pc.[Name] AS [ProductCategory]
		FROM [SalesLT].[Product] p
			INNER JOIN [SalesLT].[ProductModel] pm
			ON p.[ProductModelID] = pm.[ProductModelID]
			INNER JOIN [SalesLT].[ProductModelProductDescription] pmx
			ON pm.[ProductModelID] = pmx.[ProductModelID]
			INNER JOIN [SalesLT].[ProductDescription] pd
			ON pmx.[ProductDescriptionID] = pd.[ProductDescriptionID]
			INNER JOIN [SalesLT].[ProductCategory] pc
			ON p.[ProductCategoryID] = pc.[ProductCategoryID]
			WHERE pc.[Name] like '%bikes%' and Culture= 'EN'
			FOR JSON PATH,WITHOUT_ARRAY_WRAPPER
		)
SET @ProductContext =  REPLACE(@ProductContext,'"','\"') 

SELECT @ProductContext 
--- Ground the completion with the full product Context

DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'What is the cheapest Road Bike?'
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"system","content":"'+ @ProductContext + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
SELECT @Payload
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT 
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens

--- Create Product Details Function

CREATE OR ALTER FUNCTION dbo.GetProductDetails (@ProductID INT)
RETURNS JSON
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @productJSON VARCHAR(MAX)
	SELECT @productJSON = 
		(SELECT
		p.[ProductID]
		,p.[Name]
		,p.ListPrice
		,p.Size
		,p.Color
		,pm.[Name] AS [ProductModel]
		,pmx.[Culture]
		,pd.[Description] as [ProductDescription]
		,pc.[Name] AS [ProductCategory]
	FROM [SalesLT].[Product] p
		INNER JOIN [SalesLT].[ProductModel] pm
		ON p.[ProductModelID] = pm.[ProductModelID]
		INNER JOIN [SalesLT].[ProductModelProductDescription] pmx
		ON pm.[ProductModelID] = pmx.[ProductModelID]
		INNER JOIN [SalesLT].[ProductDescription] pd
		ON pmx.[ProductDescriptionID] = pd.[ProductDescriptionID]
		INNER JOIN [SalesLT].[ProductCategory] pc
		ON p.[ProductCategoryID] = pc.[ProductCategoryID]
		WHERE pc.[Name] like '%bikes%' and Culture= 'EN' and p.ProductID = @ProductID
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	RETURN @productJSON
END;


--- Test Product Details function 
SELECT dbo.GetProductDetails(999) 

--- Create new extended product details table inclduing product embedding vector
CREATE TABLE dbo.ProductDetailsExtended
(ProductId INT, ProductJSON JSON, ProductVector vector(1536))

--- Create base english bikes data set without vector values
INSERT INTO ProductDetailsExtended
SELECT
    p.[ProductID]
    ,dbo.GetProductDetails(p.[ProductID]) AS ProductJSON
	, NULL as ProductVector
FROM [SalesLT].[Product] p
    INNER JOIN [SalesLT].[ProductModel] pm
    ON p.[ProductModelID] = pm.[ProductModelID]
    INNER JOIN [SalesLT].[ProductModelProductDescription] pmx
    ON pm.[ProductModelID] = pmx.[ProductModelID]
    INNER JOIN [SalesLT].[ProductDescription] pd
    ON pmx.[ProductDescriptionID] = pd.[ProductDescriptionID]
	INNER JOIN [SalesLT].[ProductCategory] pc
    ON p.[ProductCategoryID] = pc.[ProductCategoryID]
WHERE pc.[Name] like '%bikes%' and Culture= 'EN'

--- View product details 
SELECT TOP(5) * FROM ProductDetailsExtended

--- Update product details with embedding vector
DECLARE @ProductID INT
DECLARE @ProductJSON VARCHAR(max)
DECLARE @ProductVector vector(1536) 
DECLARE productCursor CURSOR FOR
	SELECT ProductId, CONVERT(VARCHAR(MAX),ProductJSON) 
		FROM ProductDetailsExtended
OPEN productCursor
FETCH NEXT FROM productCursor INTO @ProductID,@ProductJSON
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC get_embedding @ProductJSON, @ProductVector output;
	UPDATE ProductDetailsExtended SET ProductVector = @ProductVector
		WHERE ProductId = @ProductID
	FETCH NEXT FROM productCursor INTO @ProductID,@ProductJSON
END
CLOSE productCursor
DEALLOCATE  productCursor 

--- View product details 
SELECT TOP(5) * FROM ProductDetailsExtended

--- Perform product vector query based on prompt embedding
DECLARE @string varchar(max)
DECLARE @QueryVector vector(1536) 
SET @string = 'what is the cheapest Mountain Bike?'
EXEC dbo.get_embedding @string, @QueryVector output;
SELECT TOP(20) *,
  vector_distance('cosine', @QueryVector, ProductVector) AS distance
  FROM ProductDetailsExtended
  ORDER BY distance

--- Perform Completion with vector search product context
DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'What is the cheapest Road Bike?'
DECLARE @QueryVector vector(1536) 
EXEC dbo.get_embedding @UserPrompt, @QueryVector output; --- < QuestionVector 
DECLARE @ProductContext  VARCHAR(MAX) 
SELECT @ProductContext = (
	SELECT TOP(20) ProductJSON
	  FROM ProductDetailsExtended
	  ORDER BY vector_distance('cosine', @QueryVector, ProductVector) 
	  FOR JSON PATH, ROOT('Products')
)
SET @ProductContext =  REPLACE(@ProductContext,'"','\"') 
-- SELECT @ProductContext
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"system","content":"'+ @ProductContext + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
-- SELECT @Payload
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT 
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens


--- Bringing it all together Conversation Context and Product Context to ground our completion

--- First conversation question
DECLARE @ConversationID BIGINT = 102
DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'What is the cheapest Road Bike?'
DECLARE @ConversationContext NVARCHAR(MAX)
SET @ConversationContext = 
		(
			SELECT * FROM (
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-1) Question : ' + UserPrompt AS MessageRow 
					FROM dbo.ChatHistory
					WHERE ConversationID=@ConversationID
				UNION ALL
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-2) Answer : ' + AssistantResponse AS MessageRow 
					FROM dbo.ChatHistory
					WHERE ConversationID=@ConversationID
				ORDER BY MessageRow Asc
			) AS Messages
			FOR XML AUTO
		)
SET @ConversationContext = 
		REPLACE(REPLACE(@ConversationContext, '<Messages MessageRow="',''),'"/>','')
SET @ConversationContext=ISNULL(@ConversationContext,'')
DECLARE @QueryVector vector(1536) 
EXEC dbo.get_embedding @UserPrompt, @QueryVector output; --- < QuestionVector 
DECLARE @ProductContext  VARCHAR(MAX) 
SELECT @ProductContext = (
	SELECT TOP(20) ProductJSON
	  FROM ProductDetailsExtended
	  ORDER BY vector_distance('cosine', @QueryVector, ProductVector) 
	  FOR JSON PATH, ROOT('Products')
)
SET @ProductContext =  REPLACE(@ProductContext,'"','\"') 
SET @ProductContext = ISNULL(@ProductContext,'')
-- SELECT @ProductContext
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"system","content":"'+ @ConversationContext + '"},
									 {"role":"system","content":"'+ @ProductContext + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
-- SELECT @Payload
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT @Response
SELECT 
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens
INSERT dbo.ChatHistory(ConversationId,UserPrompt, AssistantResponse,  PromptTokens, CompletionTokens) 
	VALUES(@ConversationID,@UserPrompt,
		JSON_VALUE(@response, '$.result.choices[0].message.content'),
		JSON_VALUE(@response, '$.result.usage.prompt_tokens') ,
		JSON_VALUE(@response, '$.result.usage.completion_tokens')
	)

-- Second Conversation Question
DECLARE @ConversationID BIGINT = 103
DECLARE @SystemPrompt NVARCHAR(MAX) = 'You are an AI assistant that helps people find information.'
DECLARE @UserPrompt NVARCHAR(MAX) = 'what is the cheapest bike for riding on gravel in the hills?'
DECLARE @ConversationContext NVARCHAR(MAX)
SET @ConversationContext = 
		(
			SELECT * FROM (
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-1) Question : ' + UserPrompt AS MessageRow 
					FROM dbo.ChatHistory
					WHERE ConversationID=@ConversationID
				UNION ALL
				SELECT TOP(10) '('+Convert(NVARChAR(Max),MessageId) + '-2) Answer : ' + AssistantResponse AS MessageRow 
					FROM dbo.ChatHistory
					WHERE ConversationID=@ConversationID
				ORDER BY MessageRow Asc
			) AS Messages
			FOR XML AUTO
		)
SET @ConversationContext = 
		REPLACE(REPLACE(@ConversationContext, '<Messages MessageRow="',''),'"/>','')
SET @ConversationContext=ISNULL(@ConversationContext,'')
DECLARE @QueryVector vector(1536) 
EXEC dbo.get_embedding @UserPrompt, @QueryVector output; --- < QuestionVector 
DECLARE @ProductContext  VARCHAR(MAX) 
SELECT @ProductContext = (
	SELECT TOP(20) ProductJSON
	  FROM ProductDetailsExtended
	  ORDER BY vector_distance('cosine', @QueryVector, ProductVector) 
	  FOR JSON PATH, ROOT('Products')
)
SET @ProductContext =  REPLACE(@ProductContext,'"','\"') 
SET @ProductContext = ISNULL(@ProductContext,'')
-- SELECT @ProductContext
DECLARE @URL NVARCHAR(4000) = N'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview';
DECLARE @Payload NVARCHAR(max) = N'{"messages":[
								     {"role":"system","content":"'+ @SystemPrompt + '"},
									 {"role":"system","content":"'+ @ConversationContext + '"},
									 {"role":"system","content":"'+ @ProductContext + '"},
									 {"role":"user","content":"'+ @UserPrompt +'"}
									 ]}'
-- SELECT @Payload
DECLARE @Response NVARCHAR(max)
EXEC [get_completion] @Payload,@Response OUTPUT
SELECT @Response
SELECT
	JSON_VALUE(@response, '$.result.choices[0].message.content') AS ResponseText,
	JSON_VALUE(@response, '$.result.usage.completion_tokens') AS CompletionTokens,
	JSON_VALUE(@response, '$.result.usage.prompt_tokens') AS PromptTokens
INSERT dbo.ChatHistory(ConversationId,UserPrompt, AssistantResponse,  PromptTokens, CompletionTokens) 
	VALUES(@ConversationID,@UserPrompt,
		JSON_VALUE(@response, '$.result.choices[0].message.content') ,
		JSON_VALUE(@response, '$.result.usage.prompt_tokens') ,
		JSON_VALUE(@response, '$.result.usage.completion_tokens')
	)
