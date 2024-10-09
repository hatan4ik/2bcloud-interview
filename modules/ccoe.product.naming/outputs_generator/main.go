package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"text/template"

	"github.com/ahmetb/go-linq/v3"
)

type Resource struct {
	Name       string `json:"name"`
	Convention string `json:"convention"`
	Code       string `json:"code"`
}

const resourcesFile = "resources.json"
const outputsFileName = "../module/outputs.tf"

func main() {
	parsedTemplate, err := template.New("templates").ParseFiles("outputs.tmpl")
	if err != nil {
		log.Fatal(err)
	}
	resourcesDefinition, err := ioutil.ReadFile(resourcesFile)
	if err != nil {
		log.Fatal(err)
	}

	var data []Resource
	err = json.Unmarshal(resourcesDefinition, &data)
	if err != nil {
		log.Fatal(err)
	}

	cleanData := linq.From(data).DistinctBy(func(i interface{}) interface{} {
		return fmt.Sprintf("%s-%s", i.(Resource).Code, i.(Resource).Convention)
	}).OrderBy(func(i interface{}) interface{} {
		return i.(Resource).Name
	}).Results()

	file, _ := json.MarshalIndent(cleanData, "", " ")
	_ = ioutil.WriteFile(resourcesFile, file, 0644)

	outputsFile, err := os.OpenFile(outputsFileName, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	parsedTemplate.ExecuteTemplate(outputsFile, "outputs", cleanData)
}
