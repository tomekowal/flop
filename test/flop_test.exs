defmodule FlopTest do
  use ExUnit.Case
  doctest Flop

  import Ecto.Query, only: [from: 2]

  alias Ecto.Query.BooleanExpr
  alias Ecto.Query.QueryExpr
  alias Flop
  alias Flop.Filter
  alias Pet

  @base_query from p in Pet, where: p.age > 8, select: p.name

  describe "query/2" do
    test "adds order_by to query if set" do
      flop = %Flop{order_by: [:species, :name], order_directions: [:asc, :desc]}

      assert [
               %QueryExpr{
                 expr: [
                   asc: {{_, _, [_, :species]}, _, _},
                   desc: {{_, _, [_, :name]}, _, _}
                 ]
               }
             ] = Flop.query(Pet, flop).order_bys

      assert [
               %QueryExpr{
                 expr: [
                   asc: {{_, _, [_, :species]}, _, _},
                   desc: {{_, _, [_, :name]}, _, _}
                 ]
               }
             ] = Flop.query(@base_query, flop).order_bys
    end

    test "uses :asc as default direction" do
      flop = %Flop{order_by: [:species, :name], order_directions: nil}

      assert [
               %QueryExpr{
                 expr: [
                   asc: {{_, _, [_, :species]}, _, _},
                   asc: {{_, _, [_, :name]}, _, _}
                 ]
               }
             ] = Flop.query(Pet, flop).order_bys

      flop = %Flop{order_by: [:species, :name], order_directions: [:desc]}

      assert [
               %QueryExpr{
                 expr: [
                   desc: {{_, _, [_, :species]}, _, _},
                   asc: {{_, _, [_, :name]}, _, _}
                 ]
               }
             ] = Flop.query(Pet, flop).order_bys

      flop = %Flop{order_by: [:species], order_directions: [:desc]}

      assert [
               %QueryExpr{
                 expr: [desc: {{_, _, [_, :species]}, _, _}]
               }
             ] = Flop.query(Pet, flop).order_bys

      flop = %Flop{order_by: [:species], order_directions: [:desc, :desc]}

      assert [
               %QueryExpr{
                 expr: [desc: {{_, _, [_, :species]}, _, _}]
               }
             ] = Flop.query(Pet, flop).order_bys
    end

    test "adds adds limit and offset to query if set" do
      flop = %Flop{limit: 10, offset: 14}

      assert %QueryExpr{params: [{14, :integer}]} = Flop.query(Pet, flop).offset
      assert %QueryExpr{params: [{10, :integer}]} = Flop.query(Pet, flop).limit
    end

    test "adds adds limit and offset to query if page and page size are set" do
      flop = %Flop{page: 1, page_size: 10}
      assert %QueryExpr{params: [{0, :integer}]} = Flop.query(Pet, flop).offset
      assert %QueryExpr{params: [{10, :integer}]} = Flop.query(Pet, flop).limit

      flop = %Flop{page: 2, page_size: 10}
      assert %QueryExpr{params: [{10, :integer}]} = Flop.query(Pet, flop).offset
      assert %QueryExpr{params: [{10, :integer}]} = Flop.query(Pet, flop).limit

      flop = %Flop{page: 3, page_size: 4}
      assert %QueryExpr{params: [{8, :integer}]} = Flop.query(Pet, flop).offset
      assert %QueryExpr{params: [{4, :integer}]} = Flop.query(Pet, flop).limit
    end

    test "adds where clauses for filters" do
      flop = %Flop{filters: [%Filter{field: :age, op: ">=", value: 4}]}

      assert [
               %BooleanExpr{
                 expr: {:>=, _, _},
                 op: :and,
                 params: [{:age, _}, {4, _}]
               }
             ] = Flop.query(Pet, flop).wheres

      flop = %Flop{
        filters: [
          %Filter{field: :age, op: ">=", value: 4},
          %Filter{field: :name, op: "==", value: "Bo"}
        ]
      }

      assert [
               %BooleanExpr{
                 expr: {:>=, _, _},
                 op: :and,
                 params: [{:age, _}, {4, _}]
               },
               %BooleanExpr{
                 expr: {:==, _, _},
                 op: :and,
                 params: [{:name, _}, {"Bo", _}]
               }
             ] = Flop.query(Pet, flop).wheres
    end

    test "leaves query unchanged if everything is nil" do
      flop = %Flop{
        filters: nil,
        limit: nil,
        offset: nil,
        order_by: nil,
        order_directions: nil,
        page: nil,
        page_size: nil
      }

      assert Flop.query(Pet, flop) == Pet
      assert Flop.query(@base_query, flop) == @base_query
    end
  end
end
