{$reference System.Runtime.dll}
unit IntervalArithmetic;
uses System;
type
  Interval = record
  private
    static tmp_arr := new double[4](0, 0, 0, 0);
    static function fmod2pi(a: real) := frac(a / (2 * pi)) * 2 * pi;
    
    static function NormPM2Pi(i: Interval): Interval;
    begin
      if (i.Max >= 2 * pi) then
      begin
        var a := fmod2pi(i.Max);
        result := new Interval(a - i.Diam(), a);
      end else
      if (i.Min <= -2 * pi) then
      begin
        var a := fmod2pi(i.Min);
        result := new Interval(a, a + i.Diam());
      end else
        result := i;
    end;
  
  public
    Min, Max: real;
    constructor create(min_, max_: real);
    begin
      if (min_ > max_) then
        raise new System.ArgumentException('min>max');
      Min := min_;
      Max := max_;
    end;
    
    function Diam() := Max - Min;
    function HasZero() := (Min <= 0) and (Max >= 0);
    function Has(v: real) := (Min <= v) and (Max >= v);
    
    //function IsPositive():=Min>0;
    //function IsNegative():=Max<0;
    //function HasNegative():=Min<0;
    //function HasPositive():=Max>0;
    
    static function FromUnsort(min_, max_: double): Interval;
    begin
      if (max_ > min_) then
        result := new Interval(min_, max_)
      else
        result := new Interval(max_, min_);
    end;
    
    static function FromSort(min_, max_: double) := new Interval(min_, max_);
    
    static function operator+(a, b: Interval) := new Interval(a.Min + b.Min, a.Max + b.Max);
    static function operator+(a: Interval; b: double) := new Interval(a.Min + b, a.Max + b);
    static function operator+(a: double; b: Interval) := new Interval(b.Min + a, b.Max + a);
    static function operator+(a: Interval) := a;
    
    
    static function operator-(a, b: Interval) := new Interval(a.Min - b.Max, a.Max - b.Min); 
    static function operator-(a: Interval; b: double) := new Interval(a.Min - b, a.Max - b);
    static function operator-(a: double; b: Interval) := new Interval(a - b.Max, a - b.Min); 
    static function operator-(a: Interval) := new Interval(-a.Max, -a.Min);
    
    static function operator*(a, b: Interval): Interval;
    begin
      lock tmp_arr do
      begin
        tmp_arr[0] := a.Min * b.Min;
        tmp_arr[1] := a.Min * b.Max;
        tmp_arr[2] := a.Max * b.Min;
        tmp_arr[3] := a.Max * b.Max;
        result := new Interval(tmp_arr.Min(), tmp_arr.Max());
      end;
    end;
    
    static function operator*(a: Interval; b: double) := Interval.FromUnsort(a.Min * b, a.Max * b);
    static function operator*(a: double; b: Interval) := Interval.FromUnsort(b.Min * a, b.Max * a);
    
    static function operator/(a, b: Interval): Interval;
    begin
      if (b.HasZero()) then raise new System.DivideByZeroException();
      lock tmp_arr do
      begin
        tmp_arr[0] := a.Min / b.Min;
        tmp_arr[1] := a.Min / b.Max;
        tmp_arr[2] := a.Max / b.Min;
        tmp_arr[3] := a.Max / b.Max;
        result := new Interval(tmp_arr.Min(), tmp_arr.Max());
      end;
    end;
    
    static function operator/(a: Interval; b: double) := Interval.FromUnsort(a.Min / b, a.Max / b);
    static function operator/(a: double; b: Interval): Interval;
    begin
      if (b.HasZero()) then raise new System.DivideByZeroException();
      result := Interval.FromUnsort(a / b.Min, a / b.Max);
    end;
    
    static function Abs(i: Interval): Interval;
    begin
      if (not i.HasZero) then
        result := Interval.FromUnsort(System.Math.Abs(i.Min), System.Math.Abs(i.Max)) else
        result := Interval.FromSort(0, System.Math.Max(System.Math.Abs(i.Min), System.Math.Abs(i.Max)));
    end;
    
    static function Power(i: Interval; exp: integer): Interval;
    begin
      if (exp < 0) then
        raise new System.ArgumentException('Exponenta can not be less than zero', 'exp');
      if (exp mod 2 = 0) and (i.HasZero()) then
        result := Interval.FromSort(0, System.Math.Max(System.Math.Pow(i.Min, exp), System.Math.Pow(i.Max, exp)))
      else
        result := Interval.FromUnsort(System.Math.Pow(i.Min, exp), System.Math.Pow(i.Max, exp));
    end;
    
    static function Power(i: Interval; exp: real): Interval;
    begin
      if (i.Min < 0) then
        raise new System.ArgumentException('Power is not defined for interval with negative values', 'i');
      result := Interval.FromUnsort(System.Math.Pow(i.Min, exp), System.Math.Pow(i.Max, exp));   
    end;
    
    static function Sqr(i: Interval): Interval;
    begin
      if (not i.HasZero) then
        result := Interval.FromUnsort(i.Min * i.Min, i.Max * i.Max) else
        result := Interval.FromSort(0, System.Math.Max(i.Min * i.Min, i.Max * i.Max));
    end;
    
    static function Sqrt(i: Interval): Interval;
    begin
      if (i.Min < 0) then raise new System.ArgumentException('Sqrt is not defined for interval with negative values');
      result := Interval.FromUnsort(System.Math.Sqrt(i.Min), System.Math.Sqrt(i.Max));
    end;
    
    static function Exp(i: Interval) := new Interval(System.Math.Exp(i.Min), System.Math.Exp(i.Max));
    
    static function Log(base: real; i: Interval): Interval;
    begin
      if (i.Min <= 0) then raise new System.ArgumentException('Sqrt is not defined for interval with non-positive values');
      result := Interval.FromUnsort(System.Math.Log(i.Min, base), System.Math.Log(i.Max, base));
    end;
    
    static function Ln(i: Interval): Interval;
    begin
      if (i.Min <= 0) then raise new System.ArgumentException('Sqrt is not defined for interval with non-positive values');
      result := Interval.FromUnsort(System.Math.Log(i.Min), System.Math.Log(i.Max));
    end;
    
    
    static function Sin(i: Interval): Interval;
    begin
      if (i.Diam() >= 2 * pi) then
      begin
        result := new Interval(-1, 1);
        exit;
      end;
      i := Interval.NormPM2Pi(i);
      var ind := integer(i.Has(pi / 2) or i.Has(-3 * pi / 2)) or (integer(i.Has(3 * pi / 2) or i.Has(-pi / 2)) * 2);
      case ind of 
        0: result := Interval.FromUnsort(System.Math.Sin(i.Min), System.Math.Sin(i.Max));
        1: result := new Interval(System.Math.Min(System.Math.Sin(i.Min), System.Math.Sin(i.Max)), 1);
        2: result := new Interval(-1, System.Math.Max(System.Math.Sin(i.Min), System.Math.Sin(i.Max)));
        3: result := new Interval(-1, 1); 
      end;
    end;
    
    static function Cos(i: Interval): Interval;
    begin
      if (i.Diam() >= 2 * pi) then
      begin
        result := new Interval(-1, 1);
        exit;
      end;
      i := Interval.NormPM2Pi(i);
      var ind := integer(i.HasZero()) or (integer(i.Has(Pi) or i.Has(-Pi)) * 2);
      case ind of 
        0: result := Interval.FromUnsort(System.Math.Cos(i.Min), System.Math.Cos(i.Max));
        1: result := new Interval(System.Math.Min(System.Math.Cos(i.Min), System.Math.Cos(i.Max)), 1);
        2: result := new Interval(-1, System.Math.Max(System.Math.Cos(i.Min), System.Math.Cos(i.Max)));
        3: result := new Interval(-1, 1); 
      end;
    end;
    
    static function ArcCos(i: Interval): Interval;
    begin
      if (i.Min < -1) or (i.Max > 1) then
        raise new System.ArgumentException('ArcCos is only define for interval [-1..1]');
      result := new Interval(Math.Acos(i.Max), Math.Acos(i.Min));
    end;
    
    static function ArcSin(i: Interval): Interval;
    begin
      if (i.Min < -1) or (i.Max > 1) then
        raise new System.ArgumentException('ArcSin is only define for interval [-1..1]');
      result := new Interval(Math.Asin(i.Min), Math.Asin(i.Max));
    end;
  end;

function Abs(i: Interval) := Interval.Abs(i);

function Power(i: interval; exp: integer) := Interval.Power(i, exp);

function Power(i: interval; exp: real) := Interval.Power(i, exp);

function Sqr(i: Interval) := Interval.Sqr(i);

function Sqrt(i: Interval) := Interval.Sqrt(i);

function Exp(i: Interval) := Interval.Exp(i);

function Ln(i: Interval) := Interval.Ln(i);

function Log(base: real; i: Interval) := Interval.Log(base, i);

function Sin(i: interval) := Interval.Sin(i);

function Cos(i: interval) := Interval.Cos(i);

begin

end. 