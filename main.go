package main

import (
	"github.com/aws/aws-sdk-go/service/comprehend"
	"github.com/aws/aws-lambda-go/events"
	"fmt"
	"encoding/json"
	"os"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-lambda-go/lambda"
)

/*
TextEvent Request Message
 */
type TextEvent struct {
	Chat    int64  `json:"chat"`
	Message string `json:"message"`
}

type store struct {
	Event     TextEvent                      `json:"event"`
	Languages []*comprehend.DominantLanguage `json:"languages"`
}
/*
HandleRequest accept a TextEvent and records the response from the comprehend service into a dynamoDB
 */
func HandleRequest(request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {

	fmt.Println(fmt.Sprintf("Received Body: %s", request.Body))

	var r TextEvent
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

	out, err := c.DetectDominantLanguage(&comprehend.DetectDominantLanguageInput{
		Text: aws.String(request.Body),
	})

	if err != nil {
		fmt.Println(fmt.Sprintf("Failed to Detect Language: %s", err.Error()))

		return events.APIGatewayProxyResponse{ // Error HTTP response
			Body:       err.Error(),
			StatusCode: 500,
		}, nil
	}

	s := &store{
		Event:     r,
		Languages: out.Languages,
	}

	item, err := dynamodbattribute.MarshalMap(s)
	if err != nil {
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
