package main

import (
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/comprehend"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/weAutomateEverything/halMessageClassification/api"
	"log"
	"os"
)

type store struct {
	MessageID  string                                   `json:"MessageID"`
	Event      api.TextEvent                            `json:"event"`
	Languages  *comprehend.DetectDominantLanguageOutput `json:"languages"`
	Sentiment  *comprehend.DetectSentimentOutput        `json:"sentiment"`
	Entities   *comprehend.DetectEntitiesOutput         `json:"entities"`
	KeyPhrases *comprehend.DetectKeyPhrasesOutput       `json:"key_phrases"`
}

/*
HandleRequest accept a TextEvent and records the response from the comprehend service into a dynamoDB
 */
func HandleRequest(request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {

	fmt.Println(fmt.Sprintf("Received Body: %s", request.Body))

	var r api.TextEvent
	err = json.Unmarshal([]byte(request.Body), &r)
	if err != nil {
		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}

	region := os.Getenv("AWS_REGION")
	session, err := session.NewSession(&aws.Config{ // Use aws sdk to connect to dynamoDB
		Region: &region,
	})
	if err != nil {
		fmt.Println(fmt.Sprintf("Failed to connect to AWS: %s", err.Error()))
		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}
	c := comprehend.New(session)

	s := store{
		Event:     r,
		MessageID: r.MessageID,
	}

	s.Languages, err = c.DetectDominantLanguage(&comprehend.DetectDominantLanguageInput{
		Text: aws.String(r.Message),
	})

	if err != nil {
		fmt.Println(fmt.Sprintf("Failed to Detect Language: %s", err.Error()))

		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}

	if len(s.Languages.Languages) > 0 {
		s.Sentiment, err = c.DetectSentiment(&comprehend.DetectSentimentInput{
			Text:         aws.String(request.Body),
			LanguageCode: s.Languages.Languages[0].LanguageCode,
		})

		if err != nil {
			fmt.Println(fmt.Sprintf("Failed to Detect Sentiment: %s", err.Error()))

			return events.APIGatewayProxyResponse{ // Error HTTP response
				Body:       err.Error(),
				StatusCode: 500,
			}, nil
		}

		s.Entities, err = c.DetectEntities(&comprehend.DetectEntitiesInput{
			LanguageCode: s.Languages.Languages[0].LanguageCode,
			Text:         aws.String(r.Message),
		})
		if err != nil {
			fmt.Println(fmt.Sprintf("Failed to Detect Entities: %s", err.Error()))

			return events.APIGatewayProxyResponse{ // Error HTTP response
				Body:       err.Error(),
				StatusCode: 500,
			}, nil
		}

		s.KeyPhrases, err = c.DetectKeyPhrases(&comprehend.DetectKeyPhrasesInput{
			Text:         aws.String(r.Message),
			LanguageCode: s.Languages.Languages[0].LanguageCode,
		})

		if err != nil {
			fmt.Println(fmt.Sprintf("Failed to Detect Entities: %s", err.Error()))

			return events.APIGatewayProxyResponse{ // Error HTTP response
				Body:       err.Error(),
				StatusCode: 500,
			}, nil
		}

	}

	item, err := dynamodbattribute.MarshalMap(s)
	fmt.Println(fmt.Sprintf("saving object: %v", item))
	if err != nil {
		log.Println(item)
		fmt.Println(fmt.Sprintf("Failed tocreate dynamo map: %s", err.Error()))

		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}
	d := dynamodb.New(session)

	input := &dynamodb.PutItemInput{
		Item:      item,
		TableName: aws.String("HAL_TEXT_AUDIT"),
	}

	dbout, err := d.PutItem(input)

	if err != nil {
		fmt.Println(fmt.Sprintf("Failed to put dynamo item: %s", err.Error()))
		log.Println(item)

		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}

	return events.APIGatewayProxyResponse{
		Body:       dbout.String(),
		StatusCode: 200,
	}, nil

}

func main() {
	lambda.Start(HandleRequest)
}
