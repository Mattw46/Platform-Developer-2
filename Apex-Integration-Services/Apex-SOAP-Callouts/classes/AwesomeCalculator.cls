public class AwesomeCalculator {
    public static Double add(Double x, Double y) {
        calculatorService.CalculatorImplPort calculator = new calculatorService.CalculatorImplPort();
        return calculator.doAdd(x,y);
    }
}