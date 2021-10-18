package main

import (
	"fmt"
	"html/template"
	"net/http"
	"path"
)

var basepath = path.Join(path.Base(""), "cmd", "simplefrontend")

func main() {
	port := 80

	http.HandleFunc("/", handlerIndex)
	http.Handle("/static/",
		http.StripPrefix("/static/",
			http.FileServer(http.Dir(path.Join(basepath, "assets")))))

	var address = fmt.Sprintf(":%d", port)
	fmt.Printf("simple frontend server started at %d\n", port)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		panic(err)
	}
}

func errorResponse(w http.ResponseWriter) {
	http.Error(w, "Internal Server Error", http.StatusInternalServerError)
}

func handlerIndex(w http.ResponseWriter, r *http.Request) {

	viewpath := path.Join(basepath, "views", "index.html")
	var tmpl, err = template.ParseFiles(viewpath)
	if err != nil {
		errorResponse(w)
		logPrint(err.Error(), false)
		return
	}

	message, err := getMessage()
	fmt.Println(message)
	if err != nil {
		errorResponse(w)
		logPrint(err.Error(), false)
		return
	}

	var data = map[string]interface{}{
		"message": message,
	}

	err = tmpl.Execute(w, data)
	if err != nil {
		errorResponse(w)
		logPrint(err.Error(), false)
	} else {
		logPrint("Index Access 200", true)
	}
}
