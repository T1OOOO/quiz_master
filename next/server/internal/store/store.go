package store

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNestedTransaction = errors.New("nested transaction")

type Tx interface {
	Commit(context.Context) error
	Rollback(context.Context) error
	Exec(context.Context, string, ...any) (pgconn.CommandTag, error)
}
type Beginner interface {
	Begin(context.Context) (Tx, error)
}
type PgxBeginner struct{ Pool *pgxpool.Pool }

func (b PgxBeginner) Begin(ctx context.Context) (Tx, error) { return b.Pool.Begin(ctx) }

type transactionKey struct{}

func WithTx(ctx context.Context, b Beginner, fn func(context.Context, Tx) error) (err error) {
	if ctx.Value(transactionKey{}) != nil {
		return ErrNestedTransaction
	}
	tx, err := b.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback(ctx)
			panic(p)
		}
		if err != nil {
			if rollbackErr := tx.Rollback(ctx); rollbackErr != nil {
				err = fmt.Errorf("%w; rollback: %v", err, rollbackErr)
			}
			return
		}
		if commitErr := tx.Commit(ctx); commitErr != nil {
			err = fmt.Errorf("commit transaction: %w", commitErr)
		}
	}()
	err = fn(context.WithValue(ctx, transactionKey{}, true), tx)
	if err != nil {
		err = fmt.Errorf("transaction callback: %w", err)
	}
	return err
}
