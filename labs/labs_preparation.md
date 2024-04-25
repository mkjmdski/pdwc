## Laboratorium
### Przetwarzanie danych w chmnurze publicznej

---


1. Wymagania wstępne - środowiska (rekomendowane **PyCharm + Anacoda**)
* PyCharm - https://www.jetbrains.com/pycharm/download/
* Anaconda - https://www.anaconda.com/products/individual#Downloads
  - nowe środowisko Python 3.9 
    Windows users : użyj Anaconda Prompt)  
    Linux / MacOs bash / zsh etc..
    ```
    conda create -n uam_cloud_dp python=3.8
    conda activate uam_cloud_dp
    ```
 
  
  
* Terraform (minimum w wersji 0.14)
  - pobierz Terraform z https://www.terraform.io/downloads.html
    właściwy dla twoje OS
  - zainstaluj zgodnie z https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started
  - sprawdź poprawność instalacji wpisując w cmdline / bash (TF w wersji 0.14+)
    ```
    $ terraform --version
    Terraform v0.14.8
    ```

* Setup środowiska 
  - Aktywuj swoją conda env
    ```
    conda activate uam_cloud_dp
    ```
  - instalacja wymaganych pakietów Python
    ```
    pip install -f <path to this repo>/labs/requirements.txt
    ```
  - sprawdź czy awscli jest zainstalowane poprawnie
    ```
    $ aws --version
    aws-cli/1.19.33 Python/3.8.8 Windows/10 botocore/1.20.33
    ```
  

* Konfiguracja konta AWS
  - Zaloguj się do AWS Educate - https://www.awseducate.com/signin/SiteLogin

  - AWS Account -> Starter Account
  - Account Details - skopiuj tymczasowe dane do logowanie (Access / Secret i Token)
    
  - jeśli pierwszy raz konfigurujsze awscli na swojej maszynie wpisz (Acces i Secret nie istotne - potem je wyedytujemy)
    ```bash
    $ aws configure
    AWS Access Key ID [None]: a
    AWS Secret Access Key [None]: b
    Default region name [None]: us-east-1
    Default output format [None]:
    ```
  - Wklej do pliku ~/.aws/credentials skopiowane dane do logowania
    






