
CREATE MASTER KEY 

CREATE DATABASE SCOPED CREDENTIAL [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings]
	WITH IDENTITY = 'Managed Identity',
	SECRET = '{"resourceid": "https://cognitiveservices.azure.com" }';


DECLARE @inputText NVARCHAR(max) = 'Apple'
DECLARE @embedding vector(1536) 
DECLARE @retval INT;
DECLARE @payload NVARCHAR(max) = json_object('input': @inputText);
DECLARE @response NVARCHAR(max)
EXEC @retval = sp_invoke_external_rest_endpoint
        @url = 'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15',
        @method = 'POST',
        @credential = [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings],
        @payload = @payload,
        @response = @response OUTPUT;
SELECT @response 
SELECT @embedding = CAST(JSON_QUERY(@response, '$.result.data[0].embedding') AS VECTOR(1536))
SELECT @embedding

CREATE or ALTER PROCEDURE [get_embedding]
@inputText nvarchar(max),
@embedding vector(1536) OUTPUT
AS
BEGIN
	DECLARE @retval INT;
	DECLARE @payload NVARCHAR(max) = json_object('input': @inputText);
	DECLARE @response NVARCHAR(max)
	EXEC @retval = sp_invoke_external_rest_endpoint
			@url = 'https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15',
			@method = 'POST',
			@credential = [https://yourOpenAIEndpoint.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings],
			@payload = @payload,
			@response = @response OUTPUT;
	SELECT @embedding = CAST(JSON_QUERY(@response, '$.result.data[0].embedding') AS VECTOR(1536))
	RETURN
END;

DECLARE @stringValue NVARCHAR(max) = 'Apple'
DECLARE @vectorValue VECTOR(1536)
EXEC get_embedding @stringValue, @vectorValue OUTPUT
SELECT @stringValue, @vectorValue

CREATE TABLE TestTableB
(stringValue varchar(max),vectorValue vector(1536))

INSERT TestTableB(stringValue) VALUES('Apple')
INSERT TestTableB(stringValue) VALUES('Banana')
INSERT TestTableB(stringValue) VALUES('Dog')
INSERT TestTableB(stringValue) VALUES('Cat')
INSERT TestTableB(stringValue) VALUES('Cilantro')
INSERT TestTableB(stringValue) VALUES('Coriander')

SELECT * FROM TestTableB

CREATE or ALTER PROCEDURE [update_embeddings]
AS
BEGIN
	DECLARE @stringValue VARCHAR(max)
	DECLARE @vectorValue VECTOR(1536) 
	DECLARE mycursor CURSOR FOR
		SELECT stringValue
			FROM TestTableB
			WHERE vectorValue IS NULL
	OPEN myCursor
	FETCH NEXT FROM mycursor INTO @stringValue
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.get_embedding @stringValue, @vectorValue OUTPUT;
		UPDATE TestTableB SET vectorValue = @vectorValue
			WHERE stringValue = @stringValue
		FETCH NEXT FROM myCursor INTO @stringValue
	END
	CLOSE myCursor
	DEALLOCATE  myCursor 
END;

SELECT * FROM TestTableB

DECLARE @CorianderVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Coriander', @CorianderVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @CorianderVector) AS cosineSimilarity 
	FROM TestTableB
		ORDER BY cosineSimilarity DESC

DECLARE @CorianderVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Eddible leaves', @CorianderVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @CorianderVector) AS cosineSimilarity 
	FROM TestTableB
		ORDER BY cosineSimilarity DESC

DECLARE @FruitVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Common household Fruit', @FruitVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @FruitVector) AS cosineSimilarity 
	FROM TestTableB
		ORDER BY cosineSimilarity DESC


INSERT TestTableB(stringValue)  VALUES('Orange')
INSERT TestTableB(stringValue)  VALUES('Grape')
INSERT TestTableB(stringValue)  VALUES('Mango')
EXEC update_embeddings

DECLARE @FruitVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Common household Fruit', @FruitVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @FruitVector) AS cosineSimilarity 
	FROM TestTableB
		ORDER BY cosineSimilarity DESC

INSERT TestTableB(stringValue) VALUES('Guitar')
INSERT TestTableB(stringValue)  VALUES('Violin')
INSERT TestTableB(stringValue)  VALUES('Piano')
INSERT TestTableB(stringValue)  VALUES('Flute')
INSERT TestTableB(stringValue)  VALUES('Drums')
INSERT TestTableB(stringValue)  VALUES('Mercury')
INSERT TestTableB(stringValue)  VALUES('Venus')
INSERT TestTableB(stringValue)  VALUES('Earth')
INSERT TestTableB(stringValue)  VALUES('Mars')
INSERT TestTableB(stringValue)  VALUES('Jupiter')
INSERT TestTableB(stringValue)  VALUES('Rain')
INSERT TestTableB(stringValue)  VALUES('Hail')
INSERT TestTableB(stringValue)  VALUES('Wind')
INSERT TestTableB(stringValue)  VALUES('Storms')
EXEC update_embeddings

DECLARE @PlanetVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Planets of the solar system', @PlanetVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @PlanetVector) as cosineSimilarity 
	FROM TestTableB
		WHERE 1-VECTOR_DISTANCE('cosine', vectorValue, @PlanetVector) > 0.80
		ORDER BY cosineSimilarity DESC

DECLARE @WeatherVector  VECTOR(1536) 
EXEC dbo.get_embedding 'Bad weather', @WeatherVector OUTPUT;
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @WeatherVector) as cosineSimilarity 
	FROM TestTableB
		WHERE 1-VECTOR_DISTANCE('cosine', vectorValue, @WeatherVector) > 0.80
		ORDER BY cosineSimilarity DESC