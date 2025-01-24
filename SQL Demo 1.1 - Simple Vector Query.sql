
SELECT @@version

CREATE TABLE TestTableA
(stringValue varchar(max),vectorValue vector(2))

INSERT TestTableA(stringValue,vectorValue) VALUES('Apple', cast('[10,50]' as vector(2)))
INSERT TestTableA(stringValue,vectorValue) VALUES('Banana', cast('[12, 48]' as vector(2)))
INSERT TestTableA(stringValue,vectorValue) VALUES('Dog', cast('[48, 12]' as vector(2)))
INSERT TestTableA(stringValue,vectorValue) VALUES('Cat', cast('[50, 10]' as vector(2)))
INSERT TestTableA(stringValue,vectorValue) VALUES('Cilantro', cast('[10, 87]' as vector(2)))
INSERT TestTableA(stringValue,vectorValue) VALUES('Coriander', cast('[10, 87]' as vector(2)))

SELECT * FROM TestTableA

DECLARE @Dog vector(2)
DECLARE @Cat vector(2)
SELECT @Dog = vectorValue FROM TestTableA WHERE stringValue='Dog'
SELECT @Cat = vectorValue FROM TestTableA WHERE stringValue='Cat'
SELECT 1-VECTOR_DISTANCE('cosine', @Dog, @Cat) AS cosineSimilarity_dog2cat

DECLARE @Apple vector(2)
DECLARE @Banana vector(2)
SELECT @Apple = vectorValue FROM TestTableA WHERE stringValue='Apple'
SELECT @Banana = vectorValue FROM TestTableA WHERE stringValue='Banana'
SELECT 1-VECTOR_DISTANCE('cosine', @Apple, @Banana) AS cosineSimilarity_apple2banana

DECLARE @Banana vector(2)
DECLARE @Dog vector(2)
SELECT @Dog = vectorValue FROM TestTableA WHERE stringValue='Dog'
SELECT @Banana = vectorValue FROM TestTableA WHERE stringValue='Banana'
SELECT 1-VECTOR_DISTANCE('cosine', @Dog, @Banana) AS cosineSimilarity_dog2banana

DECLARE @Cilantro vector(2)
DECLARE @Coriander vector(2)
SELECT @Cilantro = vectorValue FROM TestTableA WHERE stringValue='Cilantro'
SELECT @Coriander = vectorValue FROM TestTableA WHERE stringValue='Coriander'
SELECT 1-VECTOR_DISTANCE('cosine', @Cilantro, @Coriander) AS cosineSimilarity_Cilantro2Cilantro

DECLARE @Coriander vector(2)
SELECT @Coriander = vectorValue FROM TestTableA WHERE stringValue='Coriander'
SELECT stringValue,1-VECTOR_DISTANCE('cosine', vectorValue, @Coriander) as cosineSimilarity 
	FROM TestTableA
		ORDER BY cosineSimilarity DESC

-- DROP TABLE TestTableA
