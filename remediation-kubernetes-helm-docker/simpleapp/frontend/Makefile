moduleowner = github.com/lmnzr/
packagename = simplefrontend

# Build And Development
init:
	@ go mod init $(moduleowner)$(packagename)
	@ go mod vendor 
update:
	@ go mod vendor
clean:
	@ sudo rm -rf $(packagename).bin $(packagename).exe cover.txt cover.html cover.out build
run:
	@ go build -o ./build/$(packagename).bin $(moduleowner)$(packagename)/cmd/$(packagename)  && ./build/$(packagename).bin	  
docker: 
	@ docker build -t lmnzr/$(packagename):latest .
docker-push: 
	@ docker build -t lmnzr/$(packagename):latest . && docker push lmnzr/$(packagename):latest
docker-run: 
	@ docker run -p 8090:8090 -e BACKEND_URL=http://172.17.0.3:8080 lmnzr/$(packagename):latest
help:
	@ echo "$$README"