module Example
    !! @brief Módulo para exemplificar documentações.
    !!
    !! Apenas exemplifica como documentar adequadamente um código.
    implicit none

    type Vetor2D
        !! @brief Tipo derivado que representa um vetor no espaço 2D.
        !!
        !! Armazena as coordenadas cartesianas X e Y e fornece
        !! métodos para manipulação vetorial.
        real(8) :: x !< Coordenada cartesiana do eixo X.
        real(8) :: y !< Coordenada cartesiana do eixo Y.
    contains
        !> @brief Método que soma o vetor atual com outro vetor.
        procedure :: somar => somar_vetores
    end type

contains
    function somar_reais(a, b) result(soma)
        !< @brief Calcula a soma de dois números reais de precisão dupla.
        !<
        !< @details Recebe dois números reais em precisão dupla e retorna a soma
        !< algébrica deles.
        !<
        !< ### Exemplo de Uso
        !< ```fortran
        !< use Example, only: somar_reais
        !< real(8) :: resultado
        !< resultado = somar_reais(5.5_8, 4.5_8) ! Retorna 10.0_8
        !< ```
        implicit none

        !> Primeiro número
        real(8), intent(in) :: a
        !> Segundo número
        real(8), intent(in) :: b

        !> Resultado da soma algébrica
        real(8) :: soma

        soma = a + b
    end function somar_reais

    function somar_vetores(this, outro) result(resultado)
        !! @brief Função interna que realiza a soma de dois tipos Vetor2D.
        !!
        !! Esta função implementa o procedimento vinculado `somar`. Ela recebe o próprio
        !! objeto que a chamou (`this`) e um segundo vetor para computar o resultado.
        !!
        !! ### Exemplo de Uso
        !! ```fortran
        !! type(Vetor2D) :: v1, v2, v3
        !! v1 = Vetor2D(1.0_8, 2.0_8)
        !! v2 = Vetor2D(3.0_8, 4.0_8)
        !! v3 = v1%somar(v2) ! Retorna Vetor2D(4.0_8, 6.0_8)
        !! ```
        class(Vetor2D), intent(in) :: this    !< Objeto base (operando 1)
        type(Vetor2D), intent(in)  :: outro   !< Objeto somado (operando 2)
        type(Vetor2D)              :: resultado !< A soma dos vetores

        resultado%x = this%x + outro%x
        resultado%y = this%y + outro%y
    end function somar_vetores
end module
